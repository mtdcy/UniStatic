#!/bin/bash

export LANG=C

set -eo pipefail

# check on file changes on ulib.sh
UPKG_STRICT=${UPKG_STRICT:-1}

# tty,plain,silent
ULOG_MODE=${ULOG_MODE:-tty}

# enable check/tests
UPKG_CHECKS=${UPKG_CHECKS:=1}

#
ULOG_FILE=${ULOG_FILE:-upkg_static.log}

# ulog [error|info|warn] "message"
ulog() {
    local date="$(date '+%m-%d %H:%M:%S')"
    if [ "$ULOG_MODE" = "tty" ]; then
        local lvl=""
        [ $# -gt 1 ] && lvl=$(echo "$1" | tr 'A-Z' 'a-z') && shift 1
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
        echo -e "$message" > "$(tty)"
    else
        echo -e "[$date] $*"
    fi
}

# | ulog_capture logfile
ulog_capture() {
    case "$ULOG_MODE" in
        tty)
            if which tput &>/dev/null; then
                # tput: DON'T combine caps, not universal.
                local line0=$(tput hpa 0)
                local clear=$(tput el)
                local i=0
                tput rmam       # line break off
                tput dim        # half bright mode
                tee -a "$ULOG_FILE" | while read -r line; do
                    printf '%s' "${line0}${line//$'\n'/}${clear}"
                    i=$((i + 1))
                done
                tput hpa 0 el   # clear line
                tput smam       # line break on
                tput sgr0       # reset
            else
                tee -a "$ULOG_FILE"
            fi
            ;;
        plain)
            tee -a "$ULOG_FILE"
            ;;
        *)
            cat >> "$ULOG_FILE"
            ;;
    esac
}

# ulog_command <command>
ulog_command() {
    ulog info "..Run" "$@"
    eval "$*" 2>&1 | ulog_capture
}

ulog_command_silent() {
    ulog info "..Run" "$@"
    eval "$*" 2>&1 | ULOG_MODE=silent ulog_capture
}

is_darwin() {
    [[ "$OSTYPE" == "darwin"* ]]
}

is_msys() {
    [ "$OSTYPE" = "msys" ]
}

is_linux() {
    [[ "$OSTYPE" == "linux"* ]]
}

is_glibc() {
    { ldd --version 2>&1; } | grep -Fi "glibc" > /dev/null
}

is_musl() {
    # 'ldd --version' in alpine always return 1
    { ldd --version 2>&1 || true; } | grep -Fi "musl" > /dev/null
}

_prefix() {
    [ "$upkg_type" = "app" ] && echo "$APREFIX" || echo "$PREFIX"
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

is_msys && BINEXT=".exe" || BINEXT=""

# upkg_env_setup
# TODO: add support for toolchain define
upkg_env_setup() {
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
    is_darwin && which="xcrun --find" || true

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
    is_msys && CMAKE+=" -G\"MSYS Makefiles\""

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

# cleanup arguments ...
cleanup() {
    ulog info "..Run" "clean up source and installed files."

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

    ulog_command "$cmdline"
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

    ulog_command "$cmdline"
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
            install/*)  cmdline="${cmdline//-j[0-9]*/-j1}"  ;;
        esac
        ulog_command "$cmdline" "$x"
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

    ulog_command "$cmdline"
}

meson() {
    local cmdline="$MESON"

    # append user args
    cmdline+=" $(_filter_targets "$@") ${MESON_ARGS[*]} $(_filter_options "$@")"

    # remove spaces
    cmdline="$(sed -e 's/ \+/ /g' <<<"$cmdline")"

    ulog_command "$cmdline"
}

ninja() {
    local cmdline="$NINJA"

    # append user args
    cmdline+=" $*"

    # remove spaces
    cmdline="$(sed -e 's/ \+/ /g' <<<"$cmdline")"

    ulog_command "$cmdline"
}

# cmdlet_install executable(s)
cmdlet_install() {
    # strip or not ?
    for x in "$@"; do
        install -v -s -m755 "$x" "$(_prefix)/bin" 2>&1
    done
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
    fi | grep -F "$upkg_ver" 2>&1 | ulog_capture
}

# perform visual check on cmdlet
cmdlet_check() {
    ulog info "..Run" "cmdlet_check $*"
    if is_linux; then
        file "$@" | grep -F "statically linked" || {
            ldd "$@" | grep -v ".*/ld-.*\|linux-vdso.*\|libc.*" || true
        }
    elif is_darwin; then
        otool -L "$@" | grep -v "libSystem.*" || true
    else
        ulog error "FIXME: $OSTYPE"
    fi
}

# applet_install <applet(s)>
applet_install() {
    install -v -m755 "$@" "$APREFIX" 2>&1 &&

    # record installed files
    find "$APREFIX" -type f             \
        ! -name "$upkg_name.lst"        \
        -printf '%P %#m\n'              \
        > "$APREFIX/$upkg_name.lst"

    # make a gz file
    cd "$APREFIX" &&
    cut -d' ' -f1 "$upkg_name.lst" | xargs tar -cf nvim.tar.gz
}

# upkg_get <url> <sha256> [local]
upkg_get() {
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

# upkg_unzip <file> [strip]
#  => unzip to current dir
upkg_unzip() {
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
    esac 2>&1 | ULOG_MODE=silent ulog_capture
}

# prepare package sources and patches
upkg_prepare() {
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
    upkg_get "$upkg_url" "$upkg_sha" "$upkg_zip" &&

    # unzip to current fold
    upkg_unzip "$upkg_zip" "$upkg_zip_strip" &&

    # patches
    if [ -n "$upkg_patch_url" ]; then
        # download patches
        upkg_get "$upkg_patch_url" "$upkg_patch_sha" "$upkg_patch_zip"

        # unzip patches into current dir
        upkg_unzip "$upkg_patch_zip" "$upkg_patch_strip"
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
        ulog_command_silent "patch -p1 < $x"
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
    upkg_env_setup || {
        ulog error "Error" "env setup failed."
        return $?
    }

    touch "$PREFIX/packages.lst"

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

        ({  # start subshell before source
            set -eo pipefail
            ulog info ">>>>>" "#$i/${#libs[@]} $lib"

            local target="$UPKG_ROOT/libs/$lib.u"
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
            mkdir -p "$UPKG_WORKDIR/$lib-$upkg_ver" &&
            cd "$UPKG_WORKDIR/$lib-$upkg_ver" &&

            ulog info ".Path" "$PWD" &&

            upkg_prepare &&

            # delete lib from packages.lst before build
            sed -i "/^$lib.*$/d" $PREFIX/packages.lst &&

            # build library
            upkg_static &&

            # append lib to packages.lst
            echo "$lib $upkg_ver $upkg_lic" >> "$PREFIX/packages.lst" &&

            # record @ work dir
            touch "$UPKG_WORKDIR/.$lib" &&

            ulog info "<<<<<" "$lib@$upkg_ver\n"
        } || {
            ulog error "Error" "build $lib failed.\n"
            tail -v "$PWD/upkg_static.log"
            return 127
        })
    done # End for
}

if [ "$0" = "ulib.sh" ]; then
    "$@"
fi

# vim:ft=sh:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
