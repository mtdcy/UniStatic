#!/bin/bash

LANG=en_US.UTF-8
LC_ALL=$LANG

# check on file changes on ulib.sh
UPKG_STRICT=${UPKG_STRICT:-1}

# ulog [error|info|warn] "message"
ulog() {
    local lvl=""
    [ $# -gt 1 ] && lvl=$(echo "$1" | tr 'A-Z' 'a-z') && shift 1

    local date="$(date '+%m-%d %H:%M:%S')"
    local message=""

    # https://github.com/yonchu/shell-color-pallet/blob/master/color16
    case "$lvl" in
        "error")
            message="[$date] \\033[31m$1\\033[39m ${@:2}"
            ;;
        "info")
            message="[$date] \\033[32m$1\\033[39m ${@:2}"
            ;;
        "warn")
            message="[$date] \\033[33m$1\\033[39m ${@:2}"
            ;;
        *)
            message="[$date] $@"
            ;;
    esac
    echo -e $message
}

# https://unix.stackexchange.com/questions/401934/how-do-i-check-whether-my-shell-is-running-in-a-terminal
#  => wired, use 'test -t' in if condition cause failure after ulog_capture.(return value pollution?)
with_tty_input()    { test -t 0; }
with_tty_output()   { test -t 1; }

# tty,plain,silent
ULOG_MODE=${ULOG_MODE:-tty}

# | ulog_capture logfile
#   => always in append mode
#   => not capture tty message
ulog_capture() {
    case "$ULOG_MODE" in
        silent)
            tee -a "$1" > /dev/null
            ;;
        tty)
            if with_tty_output && which tput &>/dev/null; then
                local i=0
                tput rmam dim           # no line wrap, dim
                tee -a "$1" |
                    while read -r line; do
                        tput hpa 0      # move to begin of line
                        echo -n "#$i $line" # echo in the same line
                        tput el         # clear to end of line
                        i=$((i + 1))
                    done
                tput smam sgr0          # off everything
                tput hpa 0              # clear the line
                tput el
            else
                tee -a "$1"
            fi
            ;;
        *)
            tee -a "$1"
            ;;
    esac 2>&1
}

# ulog_command <command>
ulog_command() {
    ulog info "..Run" "$@"
    eval "$@" 2>&1 | ulog_capture "ulog_$(basename "$1").log"

    if [ "${PIPESTATUS[0]}" -ne 0 ]; then
        tail -v $PWD/ulog_$(basename "$1").log
        ulog error "Error" "$@ failed"
        return 1
    fi
}

# xchoose "prompt text" <expected>
#  expected: 0 - true; 1 - false
xchoose() {
    echo -en "$COLOR_GREEN== $1 "
    if [ $2 = 0 ]; then
        echo -en "[Y/n]$COLOR_RESET"
        read ans
        ans=$(echo $ans | tr A-Z a-z)
        [ "$ans" = "y" -o -z "$ans" ] && return 0
    else
        echo -en "[y/N]$COLOR_RESET"
        read ans
        ans=$(echo $ans | tr A-Z a-z)
        [ "$ans" = "n" -o -z "$ans" = "" ] && return 0
    fi
    return 1
}

# xpause "prompt text"
xpause() {
    echo -en "$COLOR_RED== $@ "
    read ans
    echo -en "$COLOR_RESET"
    return 0
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
        IFS=' ' read -r x _ <<<"$( sha256sum "$zip")"
        [ "$x" = "$sha" ] && ulog info "..Got" "$zip" && return 0

        ulog warn "Warn." "expected $sha, actual $x, broken?"
        rm $zip
    fi

    wget --quiet --show-progress "$url" -O "$zip" || {
        ulog error "Error" "get $url failed."
        return 1
    }
    ulog info "..Got" "$(sha256sum "$zip" | cut -d' ' -f1)"
}

# TODO: unzip to directory
# upkg_unzip <file> [options]
upkg_unzip() {
    ulog info ".Xzip" "$@"

    [ ! -r "$1" ] && {
        ulog error "Error" "open $1 failed."
        return 1
    }

    local dir="$(basename "$1")"
    dir=${dir%.*}   # remove extension
    dir=${dir%.tar} # remove .tar

    mkdir -p "$UPKG_WORKDIR/$dir" &&
        cd "$UPKG_WORKDIR/$dir"

    # skip leading directories, default 1
    local skip=${upkg_zip_skip:-1}
    local arg0=(--strip-components=$skip)

    if tar --version | grep -Fw bsdtar &>/dev/null; then
        arg0=(--strip-components $skip)
    fi
    # XXX: bsdtar --strip-components fails with some files like *.tar.xz
    #  ==> install gnu-tar with brew on macOS

    case "$1" in
        *.tar.lz)   tar "${arg0[@]}" --lzip -xvf "$@"   ;;
        *.tar.bz2)  tar "${arg0[@]}" -xvjf "$@"         ;;
        *.tar.gz)   tar "${arg0[@]}" -xvzf "$@"         ;;
        *.tar.xz)   tar "${arg0[@]}" -xvJf "$@"         ;;
        *.tar)      tar "${arg0[@]}" -xvf "$@"          ;;
        *.tbz2)     tar "${arg0[@]}" -xvjf "$@"         ;;
        *.tgz)      tar "${arg0[@]}" -xvzf "$@"         ;;
        *)
            rm -rf * &>/dev/null  # see notes below
            case "$1" in
                *.rar)  unrar x "$@"                    ;;
                *.zip)  unzip -o "$@"                   ;;
                *.7z)   7z x "$@"                       ;;
                *.bz2)  bunzip2 "$@"                    ;;
                *.gz)   gunzip "$@"                     ;;
                *.Z)    uncompress "$@"                 ;;
                *)      false                           ;;
            esac

            # universal skip method, faults:
            #  #1. have to clear dir before extraction.
            #  #2. will fail with bad upkg_zip_skip.
            while [ $skip -gt 0 ]; do
                mv -f */* . || true
                skip=$((skip - 1))
            done
            find . -type d -empty -delete || true
            ;;
    esac 2>&1 | ULOG_MODE=silent ulog_capture upkg_unzip.log

    if [ "${PIPESTATUS[0]}" -ne 0 ]; then
        tail -v $PWD/upkg_unzip.log
        ulog error "Error" "unzip $1 failed."
        return 1
    fi

    ulog info ".Path" "$(pwd)"
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

# provide a visual check on executables linked shared libraries
# upkg_check_linked
upkg_check_linked() {
    if upkg_linux; then
        ldd "$@"
    elif upkg_darwin; then
        otool -L "$@"
    else
        ulog error "FIXME"
    fi
}

# provide a quick check/test on executables
# upkg_check_version path/to/bin
upkg_check_version() {
    ulog info "..Run" "$@ | grep $upkg_ver"

    eval "$@ | grep $upkg_ver" 2>&1 | ulog_capture "upkg_check_version.log"

    if [ "${PIPESTATUS[0]}" -ne 0 ]; then
        tail -v $PWD/upkg_check_version.log
        ulog error "Error" "$@ | grep $upkg_ver failed"
        return 1
    fi
}

_is_cmake() {
    [ -f "CMakeLists.txt" ] && return 0

    # CMakeLists in parent dir
    [ ! -f "configure" ] && [ -f "../CMakeLists.txt" ] && return 0

    return 1
}

_is_meson() {
    [ -f meson.build ]
}

# upkg_configure arguments ...
upkg_configure() {
    local cmdline
    # cmake handle multiple platform well
    if _is_cmake; then
        cmdline="$CMAKE"    # PREFIX already set
    elif [ -f configure ]; then
        cmdline="./configure --prefix=$PREFIX"
    elif _is_meson; then    #  not familiar with it
        # meson
        cmdline="$MESON"
        # set default action
        [ $# -gt 0 ] || cmdline+=" setup build"
    else
        cmdline="$CMAKE"    # build out of source?
    fi

    # append user args
    cmdline+=" $@ ${upkg_args[@]}"

    # append default meson args
    [[ "$cmdline" =~ ^"$MESON" ]] && cmdline+=" $MESON_ARGS"

    # suffix options, override user's
    cmdline=$(sed \
        -e 's/--enable-shared //g' \
        -e 's/--disable-static //g' \
        -e 's/BUILD_SHARED_LIBS=[^\ ]* /BUILD_SHARED_LIBS=OFF /g' \
        <<<"$cmdline")

    # remove spaces
    cmdline="$(sed -e 's/ \+/ /g' <<<"$cmdline")"

    # replace UPKG_ROOT to shortten the cmdline
    ulog info "..Run" "$cmdline"

    eval "$cmdline" 2>&1 | ulog_capture upkg_configure.log

    if [ ${PIPESTATUS[0]} -ne 0 ]; then
        ulog error "Error" "$cmdline failed."
        tail -v $PWD/upkg_configure.log
        return 1
    fi
}

# upkg_make arguments ...
upkg_make() {
    local cmdline
    local targets=()

    if [ -f Makefile ] || [ -f makefile ]; then
        cmdline="$MAKE"
        #elif [ -f build.ninja ]; then
        # use script to output in non-compress way
        #cmdline="script -qfec $NINJA -- --verbose"
        # FIXME: how to pipe ninja output to file?
    fi

    while [ $# -gt 0 ]; do
        case "$1" in
            -C|-f)
                cmdline+=" $1 $2"
                shift 2 
                ;;
            -j*|*=*)
                cmdline+=" $1"
                shift 
                ;;
            *) 
                targets+=("$1")
                shift 
                ;;
        esac
    done

    # default target
    [ -z "${targets[@]}" ] && targets=(all)

    # set default njobs
    grep -- "-j[0-9\ ]\+" <<<"$cmdline"  &>/dev/null  ||
        cmdline+=" -j$UPKG_NJOBS"

    # suffix options, override user's
    cmdline="$(sed -e 's/--build-shared=[^\ ]* //g' <<<"$cmdline")"

    # remove spaces
    cmdline="$(sed -e 's/ \+/ /g' <<<"$cmdline")"

    # expand targets, as '.NOTPARALLEL' may not set for targets
    for x in "${targets[@]}"; do
        ulog info "..Run" "$cmdline $x"
        eval "$cmdline" "$x" 2>&1 | ulog_capture upkg_make.log

        if [ ${PIPESTATUS[0]} -ne 0 ]; then
            ulog error "Error" "$cmdline $x failed."
            tail -v $PWD/upkg_make.log
            return 1
        fi
    done
}

# for special case only
upkg_make_j1() {
    upkg_make "$@" -j1
}

# upkg_install arguments ...
upkg_install() {
    local cmdline
    local targets=()

    if [ -f Makefile ]; then
        cmdline="$MAKE -j1"
    elif [ -f build.ninja ]; then
        cmdline="$NINJA"
    fi

    while [ $# -gt 0 ]; do
        case "$1" in
            -j*)    ;; # no parallels for install
            -C)
                    cmdline+=" -C $2"
                                          shift 2
                                                    ;;
            *=*)
                    cmdline+=" $1"
                                          shift
                                                    ;;
            *)
                    targets+=("$1")
                                          shift
                                                    ;;
        esac
    done

    # default target
    [ "${#targets[@]}" -gt 0 ] || targets="install"

    # remove spaces
    cmdline="$(sed -e 's/ \+/ /g' <<<"$cmdline")"

    # expand targets, as '.NOTPARALLEL' may not set for targets
    for x in "${targets[@]}"; do
        ulog info "..Run" "$cmdline $x"
        eval "$cmdline" "$x" 2>&1 | ulog_capture upkg_install.log

        if [ ${PIPESTATUS[0]} -ne 0 ]; then
            ulog error "Error" "$cmdline $x failed."
            tail -v $PWD/upkg_install.log
            return 1
        fi
    done
}

# upkg_install_bin src dest
upkg_install_executables() {
    # strip or not ?
    for x in "$@"; do
        install -v -m755 "$x" "$PREFIX/bin" 2>&1 
    done | ulog_capture upkg_install.log

    if [ ${PIPESTATUS[0]} -ne 0 ]; then
        ulog error "Error" "upkg_install_bin $@ failed."
        tail -v $PWD/upkg_install.log
        return 1
    fi
}

# upkg_symlink /path/to/file link_names
upkg_symlink() {
    for x in "${@:2}"; do
        ln -sfv "$(basename "$1")" "$(dirname "$1")/$x"
    done | ulog_capture upkg_install.log
    
    if [ "${PIPESTATUS[0]}" -ne 0 ]; then
        ulog error "Error" "upkg_symlink $* failed"
        tail -v "$PWD/ulog_install.log"
        return 1
    fi
}

# upkg_uninstall arguments ...
upkg_uninstall() {
    local cmdline

    if [ -f Makefile ]; then
        cmdline="$MAKE"
    elif [ -f build.ninja ]; then
        cmdline="$NINJA"
    fi

    # fresh source?
    [ -z "$cmdline" ] && return 0

    # cmake installed files: install_manifest.txt
    if [ -f install_manifest.txt ]; then
        # no support for arguments
        [ $# -gt 0 ] && unlog warn ".Warn cmake unintall with target $@ when install_manifest.txt exists"

        # this removes files only and skip empty directories.
        cmdline="xargs rm -fv < install_manifest.txt"
    elif [ -f Makefile ]; then
        [ $# -gt 0 ] && cmdline+=" $@" || cmdline+=" uninstall"
    fi

    # remove spaces
    cmdline="$(echo $cmdline | sed -e 's/ \+/ /g')"

    ulog info "..Run" "$cmdline"

    eval $cmdline 2>&1 | ULOG_MODE=silent ulog_capture upkg_uninstall.log

    if [ ${PIPESTATUS[0]} -ne 0 ]; then
        # print warn here, uninstall fail should be ignored.
        ulog warn ".Warn" "$cmdline failed."
        tail -v $PWD/upkg_uninstall.log
    fi
}

upkg_cleanup() {
    ulog info ".Wipe" "clean up source code."

    # rm before uninstall, so uninstall will be recorded.
    rm -f ulog_*.log upkg_*.log

    upkg_uninstall || true
}

upkg_msys && BINEXT=".exe"

# upkg_env_setup
# TODO: add support for toolchain define
upkg_env_setup() {
    export UPKG_ROOT=${UPKG_ROOT:-$PWD}
    export UPKG_DLROOT=${UPKG_DLROOT:-"$UPKG_ROOT/packages"}
    export UPKG_NJOBS=${UPKG_NJOBS:-$(nproc)}

    if upkg_darwin; then
        export CC=$(xcrun --find gcc)
        export CXX=$(xcrun --find g++)
        export AR=$(xcrun --find ar)
        export AS=$(xcrun --find as)
        export LD=$(xcrun --find ld)
        export RANLIB=$(xcrun --find ranlib)
        export STRIP=$(xcrun --find strip)
        export MAKE=$(xcrun --find make)
        export PKG_CONFIG=$(xcrun --find pkg-config)
        export NASM=$(xcrun --find nasm)
        export YASM=$(xcrun --find yasm)
    else
        export CC=$(which gcc$BINEXT)
        export CXX=$(which g++$BINEXT)
        export AR=$(which ar$BINEXT)
        export AS=$(which as$BINEXT)
        export LD=$(which ld$BINEXT)
        export RANLIB=$(which ranlib$BINEXT)
        export STRIP=$(which strip$BINEXT)
        export MAKE=$(which make$BINEXT)
        export PKG_CONFIG=$(which pkg-config$BINEXT)
        export NASM=$(which nasm$BINEXT)
        export YASM=$(which yasm$BINEXT)
    fi

    local machine="$(sed 's/[0-9\.]\+$//' <<<"$( $CC -dumpmachine)")"
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

    # remove spaces
    FLAGS="$(sed -e 's/\ \+/ /g' <<<"$FLAGS")"

    export CFLAGS="$FLAGS"
    export CXXFLAGS="$FLAGS"
    export CPP="$CC -E"
    export CPPFLAGS="-I$PREFIX/include"

    #export LDFLAGS="-L$PREFIX/lib -Wl,-rpath,$PREFIX/lib -Wl,-gc-sections"
    if $CC --version | grep clang &>/dev/null; then
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
    CMAKE="$(which cmake$BINEXT)"
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
    export CMAKE="$(sed -e 's/ \+/ /g' <<<"$CMAKE")"

    # meson
    MESON="$(which meson$BINEXT)"
    # builti options: https://mesonbuild.com/Builtin-options.html
    #  libdir: some package prefer install to lib/<machine>/
    MESON_ARGS="                                    \
        -Dprefix=$PREFIX                            \
        -Dlibdir=lib                                \
        -Dbuildtype=release                         \
        -Ddefault_library=static                    \
        -Ddebug=true                                \
        -Dpkg_config_path=$PKG_CONFIG_PATH          \
    "
        #-Dprefer_static=true                        \

    # remove spaces
    export MESON="$(sed -e 's/ \+/ /g' <<<"$MESON")"

    # ninja
    NINJA="$(which ninja$BINEXT)"

    # export again after cmake and others
    export PKG_CONFIG="$PKG_CONFIG --static"

    # global common args for configure
    UPKG_ARGS=(
        --prefix="$PREFIX"
        --disable-option-checking
        --enable-silent-rules
        --disable-dependency-tracking
    )
    # disable-nls:

    # remove spaces
    export UPKG_ARG0="$(sed -e 's/ \+/ /g' <<<"$UPKG_ARG0")"
}

_deps_get() {
    ( source "$UPKG_ROOT/libs/$1.u"; echo "${upkg_dep[@]}"; )
}

# upkg_deps_get lib
upkg_deps_get() {
    local leaf=()
    local deps=($(_deps_get $1))

    while [ "${#deps[@]}" -ne 0 ]; do
        local x=("$(_deps_get ${deps[0]})")

        if [ ${#x[@]} -ne 0 ]; then
            for y in "${x[@]}"; do
                [[ "${leaf[@]}" =~ "$y" ]] || {
                    # prepend to deps and continue the while loop
                    deps=(${x[@]} ${deps[@]})
                    continue
                }
            done
        fi

        # leaf lib or all deps are meet.
        leaf+=(${deps[0]})
        deps=("${deps[@]:1}")
    done
    echo "${leaf[@]}"
}

# upkg_buld <lib list>
#  => auto build deps
upkg_build() {
    upkg_env_setup || {
        ulog error "Error" "env setup failed."
        return $?
    }

    touch $PREFIX/packages.lst

    # get full dep list before build
    local libs=()
    for lib in "$@"; do
        local deps=($(upkg_deps_get "$lib"))

        # find unmeets.
        local unmeets=()
        for x in "${deps[@]}"; do
            #1. x.u been updated 
            #2. ulib.sh been updated (UPKG_STRICT)
            #3. x been installed (skip)
            #4. x not installed
            if [ "$UPKG_ROOT/libs/$x.u" -nt "$UPKG_WORKDIR/.$x" ]; then
                unmeets+=($x)
            elif [ "$UPKG_STRICT" -ne 0 ] && [ "ulib.sh" -nt "$UPKG_WORKDIR/.$x" ]; then
                unmeets+=($x)
            elif grep -w "^$x" $PREFIX/packages.lst &>/dev/null; then
                continue
            else
                unmeets+=($x)
            fi
        done

        # does x exists in list?
        for x in "${unmeets[@]}"; do
            grep -Fw "$x" <<<"${libs[@]}" &>/dev/null || libs+=($x)
        done

        # append the lib to list.
        libs+=($lib)
    done

    ulog info "Build" "$@ (${libs[@]})"

    local i=0
    for lib in "${libs[@]}"; do
        i=$((i + 1))

        local target="$UPKG_ROOT/libs/$lib.u"
        ulog info ".Load" "#$i/${#libs[@]} $lib ==> $target" &&
            ( # start subshell before source
                source "$target"

                [ "$upkg_type" = "PHONY" ] && return || true

                # sanity check
                [ -z "$upkg_url" ] && ulog error "Error" "missing upkg_url" && return 1 || true
                [ -z "$upkg_sha" ] && ulog error "Error" "missing upkg_sha" && return 2 || true

                # local lib tarbal path
                [ -z "$upkg_zip" ] && upkg_zip="$(basename $upkg_url)" || true
                upkg_zip="$UPKG_DLROOT/$upkg_zip"

                # delete lib from packages.lst before build
                sed -i "/^$lib.*$/d" $PREFIX/packages.lst &&

                    # download lib tarbal
                    upkg_get "$upkg_url" "$upkg_sha" "$upkg_zip" &&
                    # unzip and enter source dir
                    upkg_unzip "$upkg_zip" &&
                    # build library
                    upkg_static &&

                    # append lib to packages.lst
                    echo "$lib $upkg_ver $upkg_lic" >>$PREFIX/packages.lst &&

                    # record
                    touch $UPKG_WORKDIR/.$lib &&
                    ulog info "Ready" "$lib@$upkg_ver\n"
            ) || {
            ulog error "Error" "build $lib failed.\n"
            return $?
        }
    done # End for
}

# for debug
# upkg_find <bin|lib>
upkg_find() {
    upkg_env_setup || true

    for x in "$@"; do
        # binaries ?
        ulog info "Search binaries ..."
        find "$PREFIX/bin" -name "$x*" 2>/dev/null  | sed "s%^$UPKG_ROOT/%%"

        # libraries?
        ulog info "Search libraries ..."
        find "$PREFIX/lib" -name "$x*" -o -name "lib$x*" 2>/dev/null  | sed "s%^$UPKG_ROOT/%%"

        # headers?
        ulog info "Search headers ..."
        find "$PREFIX/include" -name "$x*" -o -name "lib$x*" 2>/dev/null  | sed "s%^$UPKG_ROOT/%%"

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
