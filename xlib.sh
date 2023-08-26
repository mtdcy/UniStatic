#!/bin/bash 

# https://github.com/yonchu/shell-color-pallet/blob/master/color16
COLOR_RED="\\033[31m"
COLOR_GREEN="\\033[32m"
COLOR_YELLOW="\\033[33m"
COLOR_RESET="\\033[39m"

# xlog [error|info|warn] "message"
xlog() {
    local lvl=$(echo "$1" | tr 'A-Z' 'a-z')
    local message=""
    case "$lvl" in
        "error")
            message="[$(date '+%Y-%m-%d %H:%M:%S')] $COLOR_RED${@:2}$COLOR_RESET"
            ;;
        "info")
            message="[$(date '+%Y-%m-%d %H:%M:%S')] $COLOR_GREEN${@:2}$COLOR_RESET"
            ;;
        "warn")
            message="[$(date '+%Y-%m-%d %H:%M:%S')] $COLOR_YELLOW${@:2}$COLOR_RESET"
            ;;
        *)
            message="[$(date '+%Y-%m-%d %H:%M:%S')] $@"
            ;;
    esac

    echo -e $message 
    [ "$lvl" = "error" ] && return 1 || return 0
}

xfunction_exists() {
    declare -f $1 > /dev/null 2>&1 
    return $?
}

# xchoose "prompt text" <expected> 
#  expected: 0 - true; 1 - false
xchoose() {
	echo -en "$COLOR_GREEN== $1 "
	if [ $2 = 0 ]; then
		echo -en "[Y/n]$COLOR_RESET"
		read ans
		ans=`echo $ans | tr A-Z a-z`
		[ "$ans" = "y" -o -z "$ans" ] && return 0
	else
		echo -en "[y/N]$COLOR_RESET"
		read ans
		ans=`echo $ans | tr A-Z a-z`
		[ "$ans" = "n" -o -z "$ans" = "" ] && return 0
	fi
	return 1;
}

# xpause "prompt text"
xpause() {
    echo -en "$COLOR_RED== $@ "
    read ans;
    echo -en "$COLOR_RESET"
    return 0;
}

# xsha256 <path_to_file>
xsha256() {
    openssl dgst -sha256 $1 | awk '{print $NF}'
}

# xdownload <url> <sha256> [local]
xdownload() {
    local url=$1
    local sha=$2
    local zip=$3

    [ -z "$zip" ] && zip=$(basename "$url")

    xlog info "$url $sha => $zip"

    if [ -e "$zip" ]; then
        [ "$(xsha256 $zip)" = "$sha" ] && xlog info "$zip exists" && return 0
            
        xlog warn "$zip is broken, replace it"
        rm $zip
    fi

    which wget > /dev/null 2>&1
    if which wget > /dev/null 2>&1; then
        wget "$url" -O "$zip"
    elif which curl > /dev/null 2>&1; then
        curl "$url" --output "$zip"
    else
        xlog error "$zip download failed, missing wget & curl"
    fi
}

# xunzip <file> [options]
xunzip() {
    [ ! -f "$1" ] && xlog error "$1 doesn't exists, abort" && return 1

    case "$1" in
        *.tar.bz2)  tar -xjf "$@"   ;;
        *.tar.gz) 	tar -xzf "$@" 	;;
        *.tar.xz)   tar -xJf "$@"   ;;
        *.tar) 		tar -xf "$@" 	;;
        *.tbz2) 	tar -xjf "$@" 	;;
        *.tgz) 		tar -xzf "$@" 	;;
        *.bz2) 		bunzip2 "$@" 	;;
        *.rar) 		unrar x "$@" 	;;
        *.gz) 		gunzip "$@" 	;;
        *.zip) 		unzip "$@" 	    ;;
        *.Z) 		uncompress "$@" ;;
        *.7z) 		7z x "$@" 	    ;;
        *) 	        xlog error "$1 unknown file" && return 127 ;;
    esac
    return $?
}

# xzip  TODO
#xzip() {
#    return 1
#}

xpkg_is_macos() {
    [[ "$OSTYPE" == "darwin"* ]]
}

xpkg_is_msys() {
    [ "$OSTYPE" = "msys" ]
}

xpkg_is_linux() {
    [[ "OSTYPE" == "linxu"* ]]
}

xpkg_is_cmake() {
    [ -e "CMakeLists.txt" ] && return 0 

    # CMakeLists in parent dir
    [ ! -e "configure" -a -e "../CMakeLists.txt" ] && return 0

    # no configure too, assume we are build out of source directory
    [ ! -e "configure" ] && return 0

    return 1
}

xpkg_is_static() {
    [ -z "$XPKG_SHARED" -o $XPKG_SHARED -eq 0 ] 
}

# xpkg_configure 
xpkg_configure() {
    # prefix options, override by user's
    local cmd="./configure --prefix=$PREFIX"
    xpkg_is_cmake && cmd="$CMAKE" # PREFIX already set

    # user define options
    cmd+=" $@"

    # suffix options, override user's
    xpkg_is_static && 
        cmd=$(echo "$cmd" | sed -e 's/--enable-shared //g') ||
        cmd=$(echo "$cmd" | sed -e 's/--enable-static //g')

    xpkg_is_static && 
        cmd=$(echo "$cmd" | sed -e 's/--disable-static //g') ||
        cmd=$(echo "$cmd" | sed -e 's/--disable-shared //g')

    xpkg_is_cmake && xpkg_is_static &&
        cmd=$(echo "$cmd" | sed -e 's/XPKG_SHARED_LIB=.* /XPKG_SHARED_LIBS=OFF /g') ||
        cmd=$(echo "$cmd" | sed -e 's/XPKG_SHARED_LIB=.* /XPKG_SHARED_LIBS=ON /g')

    #xpkg_is_static && cmd+=" --static"

    xlog info "$cmd"
    eval $cmd | tee xpkg_config.log || xlog error "$cmd failed"
    return $?
}

# xpkg_make [parameters]
xpkg_make() {
    local cmd="$MAKE"

    # prefix options, override by user's

    # user defined options 
    cmd+=" $@"

    # suffix options, override user's
    xpkg_is_static &&
        cmd=$(echo "$cmd" | sed -e 's/--build-shared=.* //g') ||
        cmd=$(echo "$cmd" | sed -e 's/--build-static=.* //g')

    xlog info "$cmd"
    eval $cmd | tee xpkg_make.log || xlog error "$cmd failed"
    return $?
}

xpkg_make_njobs() {
    xpkg_make -j${XPKG_NJOBS:-1} "$@"
}

# xpkg_test [parameters]
xpkg_make_test() {
    [ -z "$XPKG_TEST" -o $XPKG_TEST -eq 0 ] && return 0

    if [ -e "CMakefile.txt" ]; then
        xlog error "FIXME: cmake test"
    else
        [ -z "$@" ] && xpkg_make test || $MAKE "$@"
    fi
}

# xpkg_env_setup 
# TODO: add support for toolchain define
xpkg_env_setup() {
    [ -z "$XPKG_ROOT" ] && { xlog error "XPKG_ROOT is not set"; return 1; }

    [ -z "$XPKG_DLROOT" ] && export XPKG_DLROOT="$XPKG_ROOT/packages"

    # set prefix to relative path to current folder 
    [ -z "$PREFIX" ] && export PREFIX="$PWD/prebuilts"

    if xpkg_is_macos; then
        export CC=`xcrun --find gcc`
        export CXX=`xcrun --find g++`
        export AR=`xcrun --find ar`
        export AS=`xcrun --find as`
        export LD=`xcrun --find ld`
        export RANLIB=`xcrun --find ranlib`
        export STRIP=`xcrun --find strip`
        export MAKE=`xcrun --find make`
        export PKG_CONFIG=`xcrun --find pkg-config`
        export NASM=`xcrun --find nasm`
        export YASM=`xcrun --find yasm`
        export CMAKE=`xcrun --find cmake`
    else
        local suffix=""
        xpkg_is_msys && suffix=".exe"
        export CC=`which gcc$suffix`
        export CXX=`which g++$suffix`
        export AR=`which ar$suffix`
        export AS=`which as$suffix`
        export LD=`which ld$suffix`
        export RANLIB=`which ranlib$suffix`
        export STRIP=`which strip$suffix`
        export MAKE=`which make$suffix`
        export PKG_CONFIG=`which pkg-config$suffix`
        export NASM=`which nasm$suffix`
        export YASM=`which yasm$suffix`
        export CMAKE=`which cmake$suffix`
    fi

    # common flags for c/c++
    local FLAGS="-g -O2 -DNDEBUG -fPIC -DPIC"  # build with debug info & PIC
    
    export CFLAGS=$FLAGS
    export CXXFLAGS=$FLAGS
    export CPP="$CC -E"
    export CPPFLAGS="-I$PREFIX/include"
    export LDFLAGS="-L$PREFIX/lib"

    xpkg_is_static || { LDFLAGS+=" -Wl,-rpath,$PREFIX/lib"; export LDFLAGS; }
    
    # pkg-config
    export PKG_CONFIG_PATH=$PREFIX/lib/pkgconfig
    export LD_LIBRARY_PATH=$PREFIX/lib     # for run test
    
    # cmake
    # cmake may affect by some environment variables but do no handle it right
    # cmake using a mixed path style with MSYS Makefiles, why???
    CMAKE+=" \
        -DCMAKE_INSTALL_PREFIX=$PREFIX \
        -DCMAKE_BUILD_TYPE=RelWithDebInfo \
        -DCMAKE_C_COMPILER=$CC \
        -DCMAKE_CXX_COMPILER=$CXX \
        -DCMAKE_C_FLAGS=\"$CFLAGS\" \
        -DCMAKE_CXX_FLAGS=\"$CXXFLAGS\" \
        -DCMAKE_ASM_NASM_COMPILER=$NASM \
        -DCMAKE_ASM_YASM_COMPILER=$YASM \
        -DCMAKE_AR=$AR \
        -DCMAKE_LINKER=$LD \
        -DCMAKE_MODULE_LINKER_FLAGS=\"$LDFLAGS\" \
        -DCMAKE_EXE_LINKER_FLAGS=\"$LDFLAGS\" \
        -DCMAKE_MAKE_PROGRAM=$MAKE" \

    xpkg_is_msys && CMAKE+=" -G\"MSYS Makefiles\""

    export CMAKE="$(echo $CMAKE | sed -e 's/ \+/ /g')"
    return 0
}

# xpkg_build <path/to/pkg.sh> 
xpkg_build() {
    xpkg_env_setup || { xlog error "env setup failed, abort."; return $?; }

    [ -d "$PREFIX" ] || mkdir -p "$PREFIX"

    xlog info "build lib $@" 

    ( 
        source "$1" 

        [ -z "$xpkg_url" -o -z "$xpkg_sha" ] && { xlog error "missing xpkg_url or xpkg_sha, abort"; return $?; }

        [ -z "$xpkg_zip" ] && xpkg_zip="$(basename $xpkg_url)"
        xpkg_zip="$XPKG_DLROOT/$xpkg_zip"

        # download lib tarbal
        xdownload "$xpkg_url" "$xpkg_sha" "$xpkg_zip" || return $?
        # unzip lib tarbal
        xunzip "$xpkg_zip" || return $?
        # enter lib source dir
        cd "$(basename ${xpkg_zip%%.*})"* || return $?

        pwd

        xfunction_exists xpkg_static || { xlog error "missing xpkg_static, abort"; return $?; }

        # build static lib
        xpkg_is_static && { xpkg_static; return $?; }

        # build shared lib 
        xfunction_exists lib_shared && { lib_shared; return $?; }

        # fallback to static lib
        xpkg_static; return $?
    ) || xlog error "build $@ failed"
    return $?
}

xpkg_build_deps() {
    for dep in "$@"; do
        [ -e "$XPKG_ROOT/build/$dep.sh" ] || return 1

        xpkg_build "$XPKG_ROOT/build/$dep.sh" || break
    done
    return $?
}

