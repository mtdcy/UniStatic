#!/bin/bash 

LANG=C.UTF-8
LC_ALL=$LANG

ULOG_VERBOSE=${ULOG_VERBOSE:-1}

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
            message="[$(date '+%Y-%m-%d %H:%M:%S')] $COLOR_RED$1$COLOR_RESET ${@:2}"
            ;;
        "info")
            message="[$(date '+%Y-%m-%d %H:%M:%S')] $COLOR_GREEN$1$COLOR_RESET ${@:2}"
            ;;
        "warn")
            message="[$(date '+%Y-%m-%d %H:%M:%S')] $COLOR_YELLOW$1$COLOR_RESET ${@:2}"
            ;;
        *)
            message="[$(date '+%Y-%m-%d %H:%M:%S')] $@"
            ;;
    esac
    echo -e $message 
}

# | ulog_capture logfile
#   => always in append mode 
#   => not capture tty message
ulog_capture() {
    local tput="$(which tput)"
    if [ $ULOG_VERBOSE -ne 0 ]; then
        tee -a "$1" | while read -r line; do
            if [ -z "$tput" ]; then
                echo "$line"
            else
                tput hpa 0          # move to begin of line
                echo -n "$line"     # echo in the same line
                tput el             # clear to end of line
            fi
        done
    else
        >> "$1"
    fi

    # clear the line
    tput hpa 0
    tput el
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

    ulog info ".Get." "$url"

    if [ -e "$zip" ]; then
        local x
        IFS=' ' read -r x _ <<< "$(sha256sum "$zip")"
        [ "$x" = "$sha" ] && ulog info "..Got" "$zip" && return 0
            
        ulog warn "Warn." "expected $sha, actual $x, broken?"
        rm $zip
    fi

    wget --quiet --show-progress "$url" -O "$zip" || {
        ulog error "Error" "get $url failed."
        return 1
    }
}

# TODO: unzip to directory
# upkg_unzip <file> [options]
upkg_unzip() {
    [ ! -r "$1" ] && {
        ulog error "Error" "open $1 failed."
        return 1
    }

    case "$1" in
        *.tar.lz)   tar --lzip -xf "$@" ;;
        *.tar.bz2)  tar -xjf "$@"       ;;
        *.tar.gz) 	tar -xzf "$@" 	    ;;
        *.tar.xz)   tar -xJf "$@"       ;;
        *.tar) 		tar -xf "$@" 	    ;;
        *.tbz2) 	tar -xjf "$@" 	    ;;
        *.tgz) 		tar -xzf "$@"       ;;
        *.bz2) 		bunzip2 "$@" 	    ;;
        *.rar) 		unrar x "$@" 	    ;;
        *.gz) 		gunzip "$@" 	    ;;
        *.zip) 		unzip -o "$@" 	    ;;
        *.Z) 		uncompress "$@"     ;;
        *.7z) 		7z x "$@" 	        ;;
        *)
            ulog error "Error" "unzip $1 failed, unsupported file."
            return 127
            ;;
    esac &&
    
    cd "$(ls -d "$(basename "$1" | sed 's/\..*$//')"* | tail -n1)" &&
    ulog info "Enter" "$(pwd)"

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

# upkg_configure arguments ...
upkg_configure() {
    # prefix options, override by user's
    local cmdline="./configure --prefix=$PREFIX"
    
    _is_cmake && cmdline="$CMAKE" # PREFIX already set

    cmdline+=" ${upkg_args[@]}"
    # user define options
    cmdline+=" $@"

    # suffix options, override user's
    cmdline=$(sed                                                       \
        -e 's/--enable-shared //g'                                  \
        -e 's/--disable-static //g'                                 \
        -e 's/BUILD_SHARED_LIBS=[^\ ]* /BUILD_SHARED_LIBS=OFF /g'   \
        <<< "$cmdline")

    # remove spaces
    cmdline="$(echo $cmdline | sed -e 's/ \+/ /g')"

    # replace UPKG_ROOT to shortten the cmdline
    ulog info "..Run" "$cmdline"

    # clear previous logs
    rm -f upkg_configure.log || true
   
    eval "$cmdline" 2>&1 | ulog_capture upkg_configure.log || {
    #eval $cmdline &> upkg_config.log || {
        ulog error "Error" "$cmdline failed."
        tail -v $PWD/upkg_configure.log
        return 1
    }
}

# upkg_make arguments ...
upkg_make() {
    local cmdline="$MAKE"
    local targets=()

    for x in "$@"; do
        case "$x" in
            -j*)    cmdline+=" $x"  ;;
            *=*)    cmdline+=" $x"  ;;
            *)      targets+=("$x") ;;
        esac
    done

    # default target
    [ -z "${targets[@]}" ] && targets=(all)

    # suffix options, override user's
    cmdline=$(sed -e 's/--build-shared=[^\ ]* //g' <<< "$cmdline")

    # remove spaces
    cmdline="$(sed -e 's/ \+/ /g' <<< "$cmdline")"

    # clear logs
    [ -e upkg_make.log ] && rm -rf upkg_make.log

    # expand targets, as '.NOTPARALLEL' may not set for targets
    for x in "${targets[@]}"; do
        ulog info "..Run" "$cmdline $x"
        eval "$cmdline" "$x" 2>&1 | ulog_capture upkg_make.log || {
            ulog error "Error" "$cmdline $x failed."
            tail -v $PWD/upkg_make.log
            return 1
        }
    done
}

# upkg_install arguments ...
upkg_install() {
    local cmdline="$MAKE"
    local targets=()

    for x in "$@"; do
        case "$x" in
            -j*)    ;; # no parallels for install
            *=*)    cmdline+=" $x"  ;;
            *)      targets+=("$x") ;;
        esac
    done

    # default target
    [ "${#targets[@]}" -gt 0 ] || targets="install"
    
    # remove spaces
    cmdline="$(sed -e 's/ \+/ /g' <<< "$cmdline")"

    # clear logs
    [ -e upkg_install.log ] && rm -rf upkg_install.log

    # expand targets, as '.NOTPARALLEL' may not set for targets
    for x in "${targets[@]}"; do
        ulog info "..Run" "$cmdline $x"
        eval "$cmdline" "$x" 2>&1 | ulog_capture upkg_install.log || {
            ulog error "Error" "$cmdline $x failed."
            tail -v $PWD/upkg_install.log
            return 1
        }
    done
}

# upkg_uninstall arguments ...
upkg_uninstall() {
    local cmdline="$MAKE"

    # cmake installed files: install_manifest.txt
    if [ -f install_manifest.txt ]; then
        # no support for arguments
        [ $# -gt 0 ] && unlog warn ".Warn cmake unintall with target $@ when install_manifest.txt exists"

        # this removes files only and skip empty directories.
        cmdline="xargs rm -fv < install_manifest.txt"
    elif [ -f Makefile ]; then
        [ $# -gt 0 ] && cmdline+=" $@"
    fi

    # remove spaces
    cmdline="$(echo $cmdline | sed -e 's/ \+/ /g')"
    
    ulog info "..Run" "$cmdline"

    eval $cmdline 2>&1 | ulog_capture upkg_uninstall.log || {
        # print warn here, uninstall fail should be ignored.
        ulog warn "Error" "$cmdline failed."
        tail -v $PWD/upkg_uninstall.log
    }
}

upkg_make_njobs() {
    upkg_make -j$UPKG_NJOBS "$@"
}

# DEPRECATED
# upkg_test [parameters]
upkg_make_test() {
    [ $UPKG_TEST -eq 0 ] && return 0

    if [ -e "CMakefile.txt" ]; then
        ulog error "FIXME" "cmake test"
    else
        [ -z "$@" ] && upkg_make test || $MAKE "$@"
    fi
}

upkg_test() {
    echo "TODO"
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
    [ -d "$PREFIX" ] || mkdir -p "$PREFIX"/{include,lib{,/pkgconfig}}

    export UPKG_WORKDIR="${UPKG_WORKDIR:-"$PWD/out/$machine"}"
    [ -d "$UPKG_WORKDIR" ] || mkdir -p "$UPKG_WORKDIR"

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

# upkg_build_lib <path/to/lib.u> 
upkg_build_lib() {
    ulog info ".Load" "$1"

    target="$1"
    [ ! -e "$target" ] && [ -e "$UPKG_ROOT/$target" ] && target="$UPKG_ROOT/$target"

    [ ! -e "$target" ] && { ulog error "Error" "load $target failed."; return $?; }
    
    upkg_env_setup || { ulog error "Error" "env setup failed."; return $?; }

    unset upkg_lic upkg_url upkg_sha upkg_zip upkg_dep upkg_args upkg_static
    source "$1" 
    local name=$(basename ${1%.u})

    [ -z "$upkg_url" ] && ulog error "Error" "missing upkg_url" && return 1
    [ -z "$upkg_sha" ] && ulog error "Error" "missing upkg_sha" && return 2

    export upkg_args=(${upkg_args[@]})

    [ -z "$upkg_zip" ] && upkg_zip="$(basename $upkg_url)"

    # local lib tarbal path
    upkg_zip="$UPKG_ROOT/packages/$upkg_zip"

    # download lib tarbal
    upkg_get "$upkg_url" "$upkg_sha" "$upkg_zip" &&

    cd "$UPKG_WORKDIR" && 

    # unzip and enter source dir
    upkg_unzip "$upkg_zip" &&
    # build library
    upkg_static || return $?
}

# upkg_buld <lib list>
#  => auto build deps
upkg_build() {
    upkg_env_setup || { ulog error "Error" "env setup failed."; return $?; }

    touch $PREFIX/packages.lst 

    local i=1
    local libs=($@)
    while [ ${#libs[@]} -ne 0 ]; do
        echo "" # put an empty line
        ulog info "Round #$i" "${libs[@]}"

        local deferred=()
        local j=0
        for lib in "${libs[@]}"; do
            j=$((j + 1))
            ulog info "Build" "[$j/${#libs[@]}] $lib" &&

            # sanity check
            if [ ! -r "$UPKG_ROOT/libs/$lib.u" ]; then
                ulog error "Error" "load $lib.u failed."
                return 1
            fi

            # check deps
            unset upkg_dep
            source "$UPKG_ROOT/libs/$lib.u"

            local defer=0
            local deps=()
            for dep in "${upkg_dep[@]}"; do
                # search packages list
                grep -w "^$dep" $PREFIX/packages.lst &> /dev/null && continue

                # add dep to deferred list
                deps+=($dep)
                defer=1
            done

            # defer: append current lib and deps to deferred list
            if [ $defer -ne 0 ]; then
                ulog warn "Defer" "$lib deps not meet (${deps[@]})."

                for x in "${deps[@]}"; do
                    grep -Fw "$x" <<< "${deferred[@]}" &> /dev/null || deferred+=($x)
                done

                deferred+=($lib)
                continue
            fi

            # delete lib from packages.lst before upkg_build_lib
            sed -i "/^$lib.*$/d" $PREFIX/packages.lst &&
            
            # build lib
            upkg_build_lib "$UPKG_ROOT/libs/$lib.u" &&

            # append lib to packages.lst
            echo "$lib $upkg_ver $upkg_lic" >> $PREFIX/packages.lst || {
                ulog error "Error" "build $lib failed."
                return $?
            }
        done # End for

        libs=(${deferred[@]})
        i=$((i + 1))
    done # End while
}

# for debug
# upkg_find <bin|lib>
upkg_find() {
    upkg_env_setup

    for x in "$@"; do
        # binaries ?
        ulog info "Search binaries ..."
        find "$PREFIX/bin" -name "$x*" 2> /dev/null | sed "s%^$UPKG_ROOT/%%"

        # libraries?
        ulog info "Search libraries ..."
        find "$PREFIX/lib" -name "$x*" -o -name "lib$x*" 2> /dev/null | sed "s%^$UPKG_ROOT/%%"

        # headers?
        ulog info "Search headers ..."
        find "$PREFIX/include" -name "$x*" -o -name "lib$x*" 2> /dev/null | sed "s%^$UPKG_ROOT/%%"
       
        # pkg-config?
        ulog info "Search pkgconfig ..."
        if $PKG_CONFIG --exists "$x"; then
            ulog info ".Found $x @ $($PKG_CONFIG --modversion "$x")"
            echo "PREFIX : $($PKG_CONFIG --variable=prefix "$x" | sed "s%^$UPKG_ROOT/%%")"
            echo "CFLAGS : $($PKG_CONFIG --static --cflags "$x" | sed "s%^$UPKG_ROOT/%%")"
            echo "LDFLAGS: $($PKG_CONFIG --static --libs "$x"   | sed "s%^$UPKG_ROOT/%%")"
            # TODO: add a sanity check here
        fi
    done
}

# vim:ft=sh:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
