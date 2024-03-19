#!/bin/bash

export LANG=C

set -eo pipefail

# check on file changes on ulib.sh
UPKG_STRICT=${UPKG_STRICT:-1}

# tty,plain,silent
ULOG_MODE=${ULOG_MODE:-tty}

# enable check/tests
UPKG_CHECKS=${UPKG_CHECKS:=1}

# https://unix.stackexchange.com/questions/401934/how-do-i-check-whether-my-shell-is-running-in-a-terminal
#  => wired, use 'test -t' in if condition cause failure after ulog_capture.(return value pollution?)
with_tty_input()    { test -t 0; }
with_tty_output()   { test -t 1; }

# ulog [error|info|warn] "message"
ulog() {
    local lvl=""
    [ $# -gt 1 ] && lvl=$(echo "$1" | tr 'A-Z' 'a-z') && shift 1

    local date="$(date '+%m-%d %H:%M:%S')"
    local message=""

    # https://github.com/yonchu/shell-color-pallet/blob/master/color16
    case "$lvl" in
        "error")
            message="[$date] \\033[31m$1\\033[39m ${*:2}"
            ;;
        "info")
            message="[$date] \\033[32m$1\\033[39m ${*:2}"
            ;;
        "warn")
            message="[$date] \\033[33m$1\\033[39m ${*:2}"
            ;;
        *)
            message="[$date] $*"
            ;;
    esac
    with_tty_output && echo -e "$message" > /dev/tty || echo -e "$message"
}

# | ulog_capture logfile
#   => always in append mode
#   => not capture tty message
ulog_capture() {
    case "$ULOG_MODE" in
        silent)
            tee -a "$1" > /dev/null
            ;;
        tty)
            if which tput &>/dev/null; then
                # tput: DON'T combine caps, not universal.
                local line0=$(tput hpa 0)
                local clear=$(tput el)
                local i=0
                tput rmam       # line break off
                tput dim        # half bright mode
                tee -a "$1" | while read -r line; do
                    printf '%s' "${line0}${line//$'\n'/}${clear}"
                    i=$((i + 1))
                done
                tput hpa 0 el   # clear line
                tput smam       # line break on
                tput sgr0       # reset
            else
                tee -a "$1"
            fi
            ;;
        *)
            tee -a "$1"
            ;;
    esac
}

# DEPRECATED
# ulog_command <command>
ulog_command() {
    ulog info "....D" "$@"
    eval "$@"
}

upkg_darwin() {
    [[ "$OSTYPE" == "darwin"* ]]
}

upkg_msys() {
    [ "$OSTYPE" = "msys" ]
}

upkg_linux() {
    [[ "$OSTYPE" == "linux"* ]]
}

upkg_glibc() {
    { ldd --version 2>&1; } | grep -Fi "glibc" > /dev/null
}

upkg_musl() {
    # 'ldd --version' in alpine always return 1
    { ldd --version 2>&1 || true; } | grep -Fi "musl" > /dev/null
}

# upkg_has <package name>
upkg_has() {
    echo "TODO"
}

# provide a visual check on executables linked shared libraries
# upkg_check_linked
upkg_check_linked() {
    ulog info "..Run" "upkg_check_linked $*" 
    if upkg_linux; then
        file "$@" | grep -F "statically linked" || ldd "$@"
    elif upkg_darwin; then
        otool -L "$@"
    else
        ulog error "FIXME"
    fi
}

# provide a quick check/test on executables
# upkg_check_version path/to/bin
upkg_check_version() {
    ulog info "....D" "$* | grep -Fw $upkg_ver"

    eval "$* | grep $upkg_ver"
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

_prefix() {
    [ "$upkg_type" = "app" ] && echo "$APREFIX" || echo "$PREFIX"
}

# upkg_configure arguments ...
upkg_configure() {
    local cmdline

    # cmake handle multiple platform well
    if _is_cmake; then
        cmdline="$CMAKE -DCMAKE_INSTALL_PREFIX=$(_prefix)"
    elif [ -f configure ]; then
        cmdline="./configure --prefix=$(_prefix)"
    elif _is_meson; then    #  not familiar with it
        # meson
        cmdline="$MESON"
        # set default action
        [ $# -gt 0 ] || cmdline+=" setup build"
    else
        # build out of source?
        cmdline="$CMAKE -DCMAKE_INSTALL_PREFIX=$(_prefix)"
    fi

    # append user args
    cmdline+=" ${upkg_args[@]} $@"

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
    ulog info "....D" "$cmdline"

    eval "$cmdline"
}

_filter_options() {
    local opts;
    while [ $# -gt 0 ]; do
        # -j1
        [[ "$1" =~ ^-j[0-9]+$ ]] && opts+=" $1" && shift && continue || true
        case "$1" in
            *=*)    opts+=" $1";    shift   ;;
            -*)     opts+=" $1 $2"; shift 2 ;;
            *)      shift ;;
        esac
    done
    echo "$opts"
}

_filter_targets() {
    local tgts;
    while [ $# -gt 0 ]; do
        [[ "$1" =~ ^-j[0-9]+$ ]] && shift && continue || true
        case "$1" in
            *=*)    shift   ;;
            -*)     shift 2 ;;
            *)      tgts+=" $1"; shift ;;
        esac
    done
    echo "$tgts"
}

# upkg_make arguments ...
upkg_make() {
    local cmdline="$MAKE"
    local targets=()

        #elif [ -f build.ninja ]; then
        # use script to output in non-compress way
        #cmdline="script -qfec $NINJA -- --verbose"
        # FIXME: how to pipe ninja output to file?

    cmdline+=" $(_filter_options "$@")"
    IFS=' ' read -r -a targets <<< "$(_filter_targets "$@")"

    # default target
    [ -z "${targets[*]}" ] && targets=(all)

    # set default njobs
    grep -- "-j[0-9\ ]\+" <<<"$cmdline"  &>/dev/null  ||
        cmdline+=" -j$UPKG_NJOBS"

    # suffix options, override user's
    cmdline="$(sed -e 's/--build-shared=[^\ ]* //g' <<<"$cmdline")"

    # remove spaces
    cmdline="$(sed -e 's/ \+/ /g' <<<"$cmdline")"

    # expand targets, as '.NOTPARALLEL' may not set for targets
    for x in "${targets[@]}"; do
        ulog info "Q.O.d" "$cmdline $x"
        eval "$cmdline" "$x"
    done
}

# upkg_install arguments ...
upkg_install() {
    local cmdline="$MAKE -j1"
    local targets

    if [ -f build.ninja ]; then
        cmdline="$NINJA"
    fi

    cmdline+=" $(_filter_options "$@")"
    IFS=' ' read -r -a targets <<< "$(_filter_targets "$@")"

    if [ "$UPKG_CHECKS" -eq 0 ]; then
        targets=("${targets[@]/check}")
        targets=("${targets[@]/tests}")
    fi

    # default target
    [ "${#targets[@]}" -gt 0 ] || targets=(install)

    # remove spaces
    cmdline="$(sed -e 's/ \+/ /g' <<<"$cmdline")"

    # expand targets, as '.NOTPARALLEL' may not set for targets
    for x in "${targets[@]}"; do
        ulog info "....D" "$cmdline $x"
        eval "$cmdline" "$x"
    done
}

# upkg_cmdlet executable(s)
upkg_cmdlet() {
    # strip or not ?
    for x in "$@"; do
        install -v -m755 "$x" "$(_prefix)/bin" 2>&1 
    done
}

# upkg_applet <applet(s)>
upkg_applet() {
    {
        install -v -m755 "$@" "$APREFIX" 2>&1 &&

        # record installed files
        find "$APREFIX" -type f             \
            ! -name "$upkg_name.lst"        \
            -printf '%P %#m\n'              \
            > "$APREFIX/$upkg_name.lst"

        # TODO: zip all files?
    }
}

# upkg_cleanup arguments ...
upkg_cleanup() {
    ulog info "Clean" "clean up source code."

    local cmdline="$MAKE $*"
    
    if [ -f build.ninja ]; then
        cmdline="$NINJA $*"
    fi

    # rm before uninstall, so uninstall will be recorded.
    rm -f ulog_*.log upkg_*.log || true

    # cmake installed files: install_manifest.txt
    if [ -f install_manifest.txt ]; then
        # no support for arguments
        [ $# -gt 0 ] && unlog warn ".Warn" "cmake unintall with target $* when install_manifest.txt exists"

        # this removes files only and skip empty directories.
        cmdline="xargs rm -fv < install_manifest.txt"
    elif [ -f Makefile ]; then
        [ $# -gt 0 ] && cmdline+=" $@" || cmdline+=" uninstall"
    else
        # no uninstall actions
        return 0
    fi

    # remove spaces
    cmdline="$(echo $cmdline | sed -e 's/ \+/ /g')"

    ulog info "..Run" "$cmdline"

    eval $cmdline | ulog_capture upkg_static.log
}

upkg_msys && BINEXT=".exe" || BINEXT=""

# _upkg_env
# TODO: add support for toolchain define
_upkg_env() {
    export UPKG_ROOT=${UPKG_ROOT:-$PWD}
    export UPKG_DLROOT=${UPKG_DLROOT:-"$UPKG_ROOT/packages"}
    export UPKG_NJOBS=${UPKG_NJOBS:-$(nproc)}

    case "$OSTYPE" in
        darwin*)    arch="$(uname -m)-apple-darwin" ;;
        *)          arch="$(uname -m)-$OSTYPE"      ;;
    esac

    export PREFIX="${PREFIX:-"$PWD/prebuilts/$arch"}"
    [ -d "$PREFIX" ] || mkdir -p "$PREFIX"/{include,lib{,/pkgconfig}}

    export UPKG_WORKDIR="${UPKG_WORKDIR:-"$PWD/out/$arch"}"
    [ -d "$UPKG_WORKDIR" ] || mkdir -p "$UPKG_WORKDIR"

    local which=which
    upkg_darwin && which="xcrun --find" || true
    
    CC="$(          $which gcc$BINEXT           )"
    CXX="$(         $which g++$BINEXT           )"
    AR="$(          $which ar$BINEXT            )"
    AS="$(          $which as$BINEXT            )"
    LD="$(          $which ld$BINEXT            )"
    RANLIB="$(      $which ranlib$BINEXT        )"
    STRIP="$(       $which strip$BINEXT         )"
    NASM="$(        $which nasm$BINEXT          )"
    YASM="$(        $which yasm$BINEXT          )"
    MAKE="$(        $which make$BINEXT          )"
    CMAKE="$(       $which cmake$BINEXT         )"
    MESON="$(       $which meson$BINEXT         )"
    NINJA="$(       $which ninja$BINEXT         )"
    PKG_CONFIG="$(  $which pkg-config$BINEXT    )"
    PATCH="$(       $which patch$BINEXT         )"

    export CC CXX AR AS LD RANLIB STRIP NASM YASM MAKE CMAKE MESON NINJA PKG_CONFIG PATCH

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

    CFLAGS="$FLAGS"
    CXXFLAGS="$FLAGS"
    CPP="$CC -E"
    CPPFLAGS="-I$PREFIX/include"

    #export LDFLAGS="-L$PREFIX/lib -Wl,-rpath,$PREFIX/lib -Wl,-gc-sections"
    if $CC --version | grep clang &>/dev/null; then
        LDFLAGS="-L$PREFIX/lib -Wl,-dead_strip"
    else
        LDFLAGS="-L$PREFIX/lib -Wl,-gc-sections"
    fi

    export CFLAGS CXXFLAGS CPP CPPFLAGS LDFLAGS

    # pkg-config
    export PKG_CONFIG_PATH=$PREFIX/lib/pkgconfig

    # for running test
    # LD_LIBRARY_PATH or rpath?
    export LD_LIBRARY_PATH=$PREFIX/lib

    # cmake
    CMAKE+="                                        \
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
    # builti options: https://mesonbuild.com/Builtin-options.html
    #  libdir: some package prefer install to lib/<machine>/
    MESON_ARGS="                                    \
        -Dprefix=$PREFIX                            \
        -Dlibdir=lib                                \
        -Dbuildtype=release                         \
        -Ddefault_library=static                    \
        -Dpkg_config_path=$PKG_CONFIG_PATH          \
    "
        #-Dprefer_static=true                        \

    # remove spaces
    export MESON="$(sed -e 's/ \+/ /g' <<<"$MESON")"

    # export again after cmake and others
    export PKG_CONFIG="$PKG_CONFIG --static"

    # global common args for configure
    local _UPKG_ARG0=(
        --prefix="$PREFIX"
        --disable-option-checking
        --enable-silent-rules
        --disable-dependency-tracking

        # static
        --disable-shared
        --enable-static

        # no nls & rpath for single static cmdlet.
        --disable-nls
        --disable-rpath
    )

    # remove spaces
    export UPKG_ARG0="${_UPKG_ARG0[*]}"
}

## override commands ##

configure() {
    local cmdline
        
    cmdline="./configure --prefix=$(_prefix)"
    
    # append user args
    cmdline+=" ${upkg_args[*]} $*"

    # suffix options, override user's
    cmdline=$(sed                       \
        -e 's/--enable-shared //g'      \
        -e 's/--disable-static //g'     \
        <<<"$cmdline")

    # remove spaces
    cmdline="$(sed -e 's/ \+/ /g' <<<"$cmdline")"

    ulog info "..Run" "$cmdline"

    eval "$cmdline" | ulog_capture upkg_static.log
}

make() {
    local cmdline="$MAKE"
    local targets=()

    cmdline+=" $(_filter_options "$@")"
    IFS=' ' read -r -a targets <<< "$(_filter_targets "$@")"

    # default target
    [ -z "${targets[*]}" ] && targets=(all)

    # set default njobs
    [[ "$cmdline" =~ -j[0-9\ ]* ]] || cmdline+=" -j$UPKG_NJOBS"

    # remove spaces
    cmdline="$(sed -e 's/ \+/ /g' <<<"$cmdline")"

    # expand targets, as '.NOTPARALLEL' may not set for targets
    for x in "${targets[@]}"; do
        case "$x" in 
            # deparallels for install target
            install)    cmdline="${cmdline//-j[0-9]*/-j1}"  ;;
        esac
        ulog info "..Run" "$cmdline $x"
        eval "$cmdline" "$x" 2>&1 | ulog_capture upkg_static.log
    done
}

cmake() {
    local cmdline

    # cmake handle multiple platform well
    cmdline="$CMAKE -DCMAKE_INSTALL_PREFIX=$(_prefix)"

    # append user args
    cmdline+=" ${upkg_args[*]} $*"

    # suffix options, override user's
    cmdline=$(sed \
        -e 's/BUILD_SHARED_LIBS=[^\ ]* /BUILD_SHARED_LIBS=OFF /g' \
        <<<"$cmdline")

    # remove spaces
    cmdline="$(sed -e 's/ \+/ /g' <<<"$cmdline")"

    ulog info "..Run" "$cmdline"

    eval "$cmdline" | ulog_capture upkg_static.log
}

meson() {
    local cmdline="$MESON"

    # append user args
    cmdline+=" $(_filter_targets "$@") ${MESON_ARGS[*]} $(_filter_options "$@")"

    # remove spaces
    cmdline="$(sed -e 's/ \+/ /g' <<<"$cmdline")"

    ulog info "..Run" "$cmdline"

    eval "$cmdline" | ulog_capture upkg_static.log
}

ninja() {
    local cmdline="$NINJA"
    
    # append user args
    cmdline+=" $*"

    # remove spaces
    cmdline="$(sed -e 's/ \+/ /g' <<<"$cmdline")"

    ulog info "..Run" "$cmdline"

    eval "$cmdline" | ulog_capture upkg_static.log
}

# cmdlet_link /path/to/file link_names
cmdlet_link() {
    for x in "${@:2}"; do
        ln -sfv "$(basename "$1")" "$(dirname "$1")/$x"
    done
}

# perform quick check with cmdlet version
# cmdlet_version /path/to/cmdlet [--version]
# cmdlet_version cmdlet [--version]
cmdlet_version() {
    ulog info "..Ver" "$* $upkg_ver"

    local cmdlet="$*"

    [[ "$cmdlet" =~ ^/ ]] || cmdlet="$PWD/$cmdlet"

    if [ -x "$cmdlet" ]; then
        # target without parameters.
        "$cmdlet" --version  2> /dev/null ||
        "$cmdlet" --help     2> /dev/null
    else
        eval "$cmdlet"
    fi | grep -Fw "$upkg_ver" | ulog_capture upkg_static.log
}

# perform visual check on cmdlet
cmdlet_check() {
    ulog info "..Run" "cmdlet_check $*" 
    if upkg_linux; then
        file "$@" | grep -F "statically linked" || {
            ldd "$@" | grep -v ".*/ld-.*\|linux-vdso.*\|libc.*" || true
        }
    elif upkg_darwin; then
        otool -L "$@" | grep -v "libSystem.*" || true
    else
        ulog error "FIXME: $OSTYPE"
    fi
}

# _upkg_get <url> <sha256> [local]
_upkg_get() {
    local url=$1
    local sha=$2
    local zip=$3

    # to current dir
    [ -z "$zip" ] && zip="$(basename "$url")"

    ulog info ".Getx" "$url"

    if [ -e "$zip" ]; then
        local x
        IFS=' ' read -r x _ <<<"$(sha256sum "$zip")"
        [ "$x" = "$sha" ] && ulog info "..Got" "$zip" && return 0

        ulog warn "Warn." "expected $sha, actual $x, broken?"
        rm $zip
    fi

    curl -L --progress-bar "$url" -o "$zip" || {
        ulog error "Error" "get $url failed."
        return 1
    }
    ulog info "..Got" "$(sha256sum "$zip" | cut -d' ' -f1)"
}

# _upkg_unzip <file> [strip]
#  unzip to current dir
_upkg_unzip() {
    ulog info ".Zipx" "$1"

    [ ! -r "$1" ] && {
        ulog error "Error" "open $1 failed."
        return 1
    }

    # skip leading directories, default 1
    local skip=${2:-1}
    local arg0=(--strip-components=$skip)

    if tar --version | grep -Fw bsdtar &>/dev/null; then
        arg0=(--strip-components $skip)
    fi
    # XXX: bsdtar --strip-components fails with some files like *.tar.xz
    #  ==> install gnu-tar with brew on macOS

    case "$1" in
        *.tar.lz)   tar "${arg0[@]}" --lzip -xvf "$1"   ;;
        *.tar.bz2)  tar "${arg0[@]}" -xvjf "$1"         ;;
        *.tar.gz)   tar "${arg0[@]}" -xvzf "$1"         ;;
        *.tar.xz)   tar "${arg0[@]}" -xvJf "$1"         ;;
        *.tar)      tar "${arg0[@]}" -xvf "$1"          ;;
        *.tbz2)     tar "${arg0[@]}" -xvjf "$1"         ;;
        *.tgz)      tar "${arg0[@]}" -xvzf "$1"         ;;
        *)
            rm -rf * &>/dev/null  # see notes below
            case "$1" in
                *.rar)  unrar x "$1"                    ;;
                *.zip)  unzip -o "$1"                   ;;
                *.7z)   7z x "$1"                       ;;
                *.bz2)  bunzip2 "$1"                    ;;
                *.gz)   gunzip "$1"                     ;;
                *.Z)    uncompress "$1"                 ;;
                *)      false                           ;;
            esac

            # universal skip method, faults:
            #  #1. have to clear dir before extraction.
            #  #2. will fail with bad upkg_zip_strip.
            while [ $skip -gt 0 ]; do
                mv -f */* . || true
                skip=$((skip - 1))
            done
            find . -type d -empty -delete || true
            ;;
    esac | ULOG_MODE=silent ulog_capture upkg_static.log
}

_upkg_prepare() {
    # check upkg_zip
    [ -z "$upkg_zip" ] && upkg_zip="$(basename "$upkg_url")" || true
    upkg_zip="$UPKG_DLROOT/${upkg_zip##*/}"

    # check upkg_zip_strip, default: 1
    upkg_zip_strip=${upkg_zip_strip:-1}

    # check upkg_patch_*
    if [ -n "$upkg_patch_url" ]; then
        [ -z "$upkg_patch_zip" ] && upkg_patch_zip="$(basename "$upkg_patch_url")" || true
        upkg_patch_zip="$UPKG_DLROOT/${upkg_patch_zip##*/}"

        upkg_patch_strip=${upkg_patch_strip:-0}
    fi

    # download lib tarbal
    _upkg_get "$upkg_url" "$upkg_sha" "$upkg_zip" &&

    # unzip to current fold
    _upkg_unzip "$upkg_zip" "$upkg_zip_strip" &&

    # patches
    if [ -n "$upkg_patch_url" ]; then
        # download patches
        _upkg_get "$upkg_patch_url" "$upkg_patch_sha" "$upkg_patch_zip"

        # unzip patches into current dir
        _upkg_unzip "$upkg_patch_zip" "$upkg_patch_strip"
    fi

    # apply patches
    mkdir -p patches
    for x in "${upkg_patches[@]}"; do
        # url(sha)
        if [[ "$x" =~ ^http* ]]; then
            IFS='()' read -r a b _ <<< "$x"
                        
            # download to patches/
            "$a" "$b" "patches/$(basename "$a")"

            x="patches/$a"
        fi

        # apply patch
        ulog info "..Run" "patch -p1 < $x"
        patch -p1 < "$x" | ULOG_MODE=silent ulog_capture upkg_static.log
    done 
}

_deps_get() {
    ( source "$UPKG_ROOT/libs/$1.u"; echo "${upkg_dep[@]}"; )
}

# _upkg_deps lib
_upkg_deps() {
    local leaf=()
    local deps=($(_deps_get $1))

    while [ "${#deps[@]}" -ne 0 ]; do
        local x=("$(_deps_get ${deps[0]})")

        if [ ${#x[@]} -ne 0 ]; then
            for y in "${x[@]}"; do
                [[ "${leaf[*]}" =~ "$y" ]] || {
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
    _upkg_env || {
        ulog error "Error" "env setup failed."
        return $?
    }

    touch $PREFIX/packages.lst

    # get full dep list before build
    local libs=()
    for lib in "$@"; do
        local deps=($(_upkg_deps "$lib"))

        # find unmeets.
        local unmeets=()
        for x in "${deps[@]}"; do
            #1. x.u been updated 
            #2. ulib.sh been updated (UPKG_STRICT)
            #3. x been installed (skip)
            #4. x not installed
            if [ "$UPKG_STRICT" -ne 0 ] && [ -e "$UPKG_WORKDIR/.$x" ]; then
                if [ "$UPKG_ROOT/libs/$x.u" -nt "$UPKG_WORKDIR/.$x" ]; then
                    unmeets+=($x)
                elif [ "ulib.sh" -nt "$UPKG_WORKDIR/.$x" ]; then
                    unmeets+=($x)
                fi
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

    ulog info "Build" "$* (${libs[*]})"

    local i=0
    for lib in "${libs[@]}"; do
        i=$((i + 1))

        ulog info ">>>>>" "#$i/${#libs[@]} $lib"
        local target="$UPKG_ROOT/libs/$lib.u"

        ({  # start subshell before source
            ulog info ".Load" "$target"
            source "$target"

            [ "$upkg_type" = "PHONY" ] && return || true

            # sanity check
            [ -z "$upkg_url" ] && ulog error "Error" "missing upkg_url" && return 1 || true
            [ -z "$upkg_sha" ] && ulog error "Error" "missing upkg_sha" && return 2 || true

            # check upkg_name
            [ -z "$upkg_name" ] && upkg_name="$lib" || true

            # set PREFIX for app
            [ "$upkg_type" = "app" ] && APREFIX="$PREFIX/app/$upkg_name" || true

            # prepare work dir
            mkdir -p "$UPKG_WORKDIR/$upkg_name-$upkg_ver" &&
            cd "$UPKG_WORKDIR/$upkg_name-$upkg_ver" &&

            ulog info ".Path" "$PWD" &&

            _upkg_prepare &&
            
            # delete lib from packages.lst before build
            sed -i "/^$lib.*$/d" $PREFIX/packages.lst &&

            # build library
            upkg_static &&

            # append lib to packages.lst
            echo "$upkg_name $upkg_ver $upkg_lic" >> "$PREFIX/packages.lst" &&

            # record @ work dir
            touch "$UPKG_WORKDIR/.$upkg_name" &&

            ulog info "<<<<<" "$upkg_name@$upkg_ver\n"
        } || {
            ulog error "Error" "build $lib failed.\n"
            tail -v "$PWD/upkg_static.log"
            return 127
        })
    done # End for
}


# vim:ft=sh:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
