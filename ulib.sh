#!/bin/bash 

LANG=en_US.UTF-8
LC_ALL=$LANG

# https://github.com/yonchu/shell-color-pallet/blob/master/color16
COLOR_RED="\\033[31m"
COLOR_GREEN="\\033[32m"
COLOR_YELLOW="\\033[33m"
COLOR_RESET="\\033[39m"

# ulog [error|info|warn] "message"
ulog() {
    local lvl=""
    [ $# -gt 1 ] && lvl=$(echo "$1" | tr 'A-Z' 'a-z') && shift 1

    local message=""
    case "$lvl" in
        "error")
            message="[$(date '+%Y-%m-%d %H:%M:%S')] $COLOR_RED$@$COLOR_RESET"
            ;;
        "info")
            message="[$(date '+%Y-%m-%d %H:%M:%S')] $COLOR_GREEN$@$COLOR_RESET"
            ;;
        "warn")
            message="[$(date '+%Y-%m-%d %H:%M:%S')] $COLOR_YELLOW$@$COLOR_RESET"
            ;;
        *)
            message="[$(date '+%Y-%m-%d %H:%M:%S')] $@"
            ;;
    esac
    echo -e $message 
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

# upkg_get <url> <sha256> [local]
upkg_get() {
    local url=$1
    local sha=$2
    local zip=$3

    [ -z "$zip" ] && zip=$(basename "$url")

    ulog info "Get $url $sha => $zip"

    if [ -e "$zip" ]; then
        local x
        IFS=' ' read -r x _ <<< "$(sha256sum "$zip")"
        [ "$x" = "$sha" ] && ulog info "Using $zip" && return 0
            
        ulog warn "$zip is broken, expected $sha, actual $x"
        rm $zip
    fi

    wget --quiet --show-progress "$url" -O "$zip" || {
        ulog error "Get $url failed."
        return 1
    }
}

# TODO: unzip to directory
# upkg_unzip <file> [options]
upkg_unzip() {
    [ ! -f "$1" ] && ulog error "$1 doesn't exists, abort" && return 1

    case "$1" in
        *.tar.bz2)  tar -xjf "$@"   ;;
        *.tar.gz) 	tar -xzf "$@" 	;;
        *.tar.xz)   tar -xJf "$@"   ;;
        *.tar) 		tar -xf "$@" 	;;
        *.tbz2) 	tar -xjf "$@" 	;;
        *.tgz) 		tar -xzf "$@"   ;;
        *.bz2) 		bunzip2 "$@" 	;;
        *.rar) 		unrar x "$@" 	;;
        *.gz) 		gunzip "$@" 	;;
        *.zip) 		unzip -o "$@" 	;;
        *.Z) 		uncompress "$@" ;;
        *.7z) 		7z x "$@" 	    ;;
        *) 	        ulog error "$1 unknown file" && return 127 ;;
    esac &&
    
    cd "$(ls -d "$(basename "$1" | sed 's/\..*$//')"* | tail -n1)" && pwd

    return $?
}

# xzip  TODO
#xzip() {
#    return 1
#}

upkg_darwin() {
    [[ "$OSTYPE" == "darwin"* ]]
}

upkg_msys() {
    [ "$OSTYPE" = "msys" ]
}

upkg_linux() {
    [[ "$OSTYPE" == "linux"* ]]
}

upkg_is_static() {
    true
}

# upkg_has <package name>
upkg_has() {
    echo "TODO"
}

# upkg_print_linked 
upkg_print_linked() {
    if upkg_linux; then
        ldd "$@"
    elif upkg_darwin; then
        otool -L "$@"
    else
        ulog error "FIXME"
    fi
}

_is_cmake() {
    [ -e "CMakeLists.txt" ] && return 0 

    # CMakeLists in parent dir
    [ ! -e "configure" -a -e "../CMakeLists.txt" ] && return 0

    # no configure too, assume we are build out of source directory
    [ ! -e "configure" ] && return 0

    return 1
}

# upkg_configure 
upkg_configure() {
    # prefix options, override by user's
    local cmd="./configure --prefix=$PREFIX"
    
    _is_cmake && cmd="$CMAKE" # PREFIX already set

    cmd+=" ${upkg_args[@]}"
    # user define options
    cmd+=" $@"

    # suffix options, override user's
    cmd=$(sed                                                       \
        -e 's/--enable-shared //g'                                  \
        -e 's/--disable-static //g'                                 \
        -e 's/BUILD_SHARED_LIBS=[^\ ]* /BUILD_SHARED_LIBS=OFF /g'   \
        <<< "$cmd")

    # remove spaces
    cmd="$(echo $cmd | sed -e 's/ \+/ /g')"

    ulog info "$cmd"
    eval $cmd 2>&1 | tee upkg_config.log

    local saved="${PIPESTATUS[0]}"
    [ "$saved" -ne 0 ] && ulog error "$cmd failed"
    return "$saved"
}

# upkg_make [parameters]
upkg_make() {
    local cmd="$MAKE"

    # prefix options, override by user's

    # user defined options 
    cmd+=" $@"

    # suffix options, override user's
    cmd=$(echo "$cmd" | sed -e 's/--build-shared=[^\ ]* //g')

    # remove spaces
    cmd="$(echo $cmd | sed -e 's/ \+/ /g')"

    ulog info "$cmd"
    eval $cmd 2>&1 | tee upkg_make.log

    local saved="${PIPESTATUS[0]}"
    [ "$saved" -ne 0 ] && ulog error "$cmd failed"
    return "$saved"
}

# upkg_install [parameters]
upkg_install() {
    local cmd="$MAKE"
    
    # user defined options 
    [ $# -ne 0 ] && cmd+=" $@" || cmd+=" install"

    # remove spaces
    cmd="$(echo $cmd | sed -e 's/ \+/ /g')"
    
    ulog info "$cmd"
    eval $cmd 2>&1 | tee upkg_install.log

    local saved="${PIPESTATUS[0]}"
    [ "$saved" -ne 0 ] && ulog error "$cmd failed"
    return "$saved"
}

upkg_uninstall() {
    local cmd="$MAKE"
    
    # user defined options 
    [ $# -ne 0 ] && cmd+=" $@" || cmd+=" uninstall"

    # remove spaces
    cmd="$(echo $cmd | sed -e 's/ \+/ /g')"
    
    ulog info "$cmd"
    eval $cmd 2>&1 | tee upkg_uninstall.log

    local saved="${PIPESTATUS[0]}"
    [ "$saved" -ne 0 ] && ulog error "$cmd failed"
    return "$saved"
}

upkg_make_njobs() {
    upkg_make -j$UPKG_NJOBS "$@"
}

# upkg_test [parameters]
upkg_make_test() {
    [ $UPKG_TEST -eq 0 ] && return 0

    if [ -e "CMakefile.txt" ]; then
        ulog error "FIXME: cmake test"
    else
        [ -z "$@" ] && upkg_make test || $MAKE "$@"
    fi
}

# upkg_env_setup 
# TODO: add support for toolchain define
upkg_env_setup() {
    export UPKG_ROOT=${UPKG_ROOT:-$PWD}
    
    export UPKG_NJOBS=${UPKG_NJOBS:-$(nproc)}
    export UPKG_TEST=${UPKG_TEST:-0}

    if upkg_darwin; then
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
        upkg_msys && suffix=".exe"
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

    local machine="$(sed 's/[0-9\.]\+$//' <<< "$($CC -dumpmachine)")"

    export PREFIX="${PREFIX:-"$PWD/prebuilts/$machine"}"
    [ -d "$PREFIX" ] || mkdir -pv "$PREFIX"/{include,lib{,/pkgconfig}}

    export UPKG_WORKDIR="${UPKG_WORKDIR:-"$PWD/out/$machine"}"
    [ -d "$UPKG_WORKDIR" ] || mkdir -pv "$UPKG_WORKDIR"

    # common flags for c/c++
    # build with debug info & PIC
    local FLAGS="           \
        -g -O3 -fPIC -DPIC  \
        -ffunction-sections \
        "
        # some libs may fail.
        #-fdata-sections    \

    # some test may fail with '-DNDEBUG'
    [ $UPKG_TEST -eq 0 ] && FLAGS+=" -DNDEBUG"

    # remove spaces
    FLAGS="$(sed -e 's/\ \+/ /g' <<< "$FLAGS")"
    
    export CFLAGS="$FLAGS"
    export CXXFLAGS="$FLAGS"
    export CPP="$CC -E"
    export CPPFLAGS="-I$PREFIX/include"
   
    #export LDFLAGS="-L$PREFIX/lib -Wl,-rpath,$PREFIX/lib -Wl,-gc-sections"
    if $CC --version | grep clang &> /dev/null; then
        export LDFLAGS="-L$PREFIX/lib -Wl,-dead_strip"
    else
        export LDFLAGS="-L$PREFIX/lib -Wl,-gc-sections"
    fi
    
    # pkg-config
    export PKG_CONFIG_PATH=$PREFIX/lib/pkgconfig

    # for running test 
    # LD_LIBRARY_PATH or rpath?
    export LD_LIBRARY_PATH=$PREFIX/lib     
    
    # cmake
    CMAKE+="                                        \
        -DCMAKE_INSTALL_PREFIX=$PREFIX              \
        -DCMAKE_PREFIX_PATH=$PREFIX                 \
        -DCMAKE_BUILD_TYPE=RelWithDebInfo           \
        -DCMAKE_C_COMPILER=$CC                      \
        -DCMAKE_CXX_COMPILER=$CXX                   \
        -DCMAKE_C_FLAGS=\"$CFLAGS\"                 \
        -DCMAKE_CXX_FLAGS=\"$CXXFLAGS\"             \
        -DCMAKE_ASM_NASM_COMPILER=$NASM             \
        -DCMAKE_ASM_YASM_COMPILER=$YASM             \
        -DCMAKE_AR=$AR                              \
        -DCMAKE_LINKER=$LD                          \
        -DCMAKE_MODULE_LINKER_FLAGS=\"$LDFLAGS\"    \
        -DCMAKE_EXE_LINKER_FLAGS=\"$LDFLAGS\"       \
        -DCMAKE_MAKE_PROGRAM=$MAKE                  \
    "

    # cmake using a mixed path style with MSYS Makefiles, why???
    upkg_msys && CMAKE+=" -G\"MSYS Makefiles\""

    # remove spaces
    export CMAKE="$(sed -e 's/ \+/ /g' <<< "$CMAKE")"

    return 0
}

# upkg_build <path/to/lib.u> 
upkg_build() {
    ulog info "Build $@" 

    target="$1"
    [ ! -e "$target" ] && [ -e "$UPKG_ROOT/$target" ] && target="$UPKG_ROOT/$target"

    [ ! -e "$target" ] && { ulog error "target $target not exists, abort."; return $?; }
    
    upkg_env_setup || { ulog error "env setup failed, abort."; return $?; }
    
    ( 
        unset upkg_lic upkg_url upkg_sha upkg_zip upkg_dep upkg_args upkg_static
        source "$1" 
        local name=$(basename ${1%.u})

        [ -z "$upkg_url" ] && ulog error "missing upkg_url, abort" && return 1
        [ -z "$upkg_sha" ] && ulog error "missing upkg_sha, abort" && return 2

        export upkg_args=(${upkg_args[@]})

        [ -z "$upkg_zip" ] && upkg_zip="$(basename $upkg_url)"

        # local lib tarbal path
        upkg_zip="$UPKG_ROOT/packages/$upkg_zip"

        # download lib tarbal
        upkg_get "$upkg_url" "$upkg_sha" "$upkg_zip" &&

        cd "$UPKG_WORKDIR" && 
        # unzip and enter source dir
        upkg_unzip "$upkg_zip" &&
        ulog info "Enter $(pwd)" &&
        # build library
        upkg_static
    ) || { ulog error "build $@ failed"; return 127; }
}

upkg_build_deps() {
    upkg_env_setup || { ulog error "env setup failed, abort."; return $?; }

    touch $PREFIX/packages.lst 

    local libs=($@)
    while [ ${#libs[@]} -ne 0 ]; do
        local deferred=()
        for lib in "${libs[@]}"; do
            [ ! -e "$UPKG_ROOT/libs/$lib.u" ] &&
            ulog error "cann't find $lib.u" &&
            return 1

            local defer=0
            unset upkg_dep
            source "$UPKG_ROOT/libs/$lib.u"
            for dep in "${upkg_dep[@]}"; do
                # search packages list
                grep -w "^$dep" $PREFIX/packages.lst && continue

                ulog warn "$lib: missing dependency $dep, defer it..."
                # add dependency to deferred list
                deferred+=($dep)
                defer=1
            done

            # add lib to deferred list
            [ $defer -ne 0 ] && deferred+=($lib) && continue

            sed -i "/^$lib.*$/d" $PREFIX/packages.lst &&
            upkg_build "$UPKG_ROOT/libs/$lib.u" &&
            echo "$lib $upkg_ver $upkg_lic" >> $PREFIX/packages.lst || return $?
        done
        libs=(${deferred[@]})
    done
    return $?
}

# vim:ft=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
