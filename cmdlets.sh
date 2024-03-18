#!/bin/bash

set -e 
export LANG=C LC_CTYPE=UTF-8

ROOT="$(realpath "$(dirname "$0")")"
BASE=https://git.mtdcy.top:8443/mtdcy/UniStatic/raw/branch/main/cmdlets.sh
REPO=https://pub.mtdcy.top:8443/UniStatic/current

info() { echo -ne "\\033[32m$*\\033[39m"; }
warn() { echo -ne "\\033[33m$*\\033[39m"; }

case "$OSTYPE" in
    darwin*)    arch="$(uname -m)-apple-darwin" ;;
    *)          arch="$(uname -m)-$OSTYPE"      ;;
esac

# accept ENV:CMDLET_ARCH
arch=${CMDLETS_ARCH:-$arch}

# pull cmdlet from server
pull_cmdlet() {
    # is app exists?
    local dest="prebuilts/$arch/app/$1"

    # get app.lst
    if curl --fail-with-body -s -o "/tmp/$$_$1.lst" "$REPO/$dest/$1.lst"; then
        mkdir -p "$ROOT/$dest" && 
        mv "/tmp/$$_$1.lst" "$ROOT/$dest/$1.lst" &&

        tput hpa 0 el 
        local message="Pull $REPO/$dest => $dest"

        local w="${#message}"
        info "$message"

        # get files
        local i=0
        local n="$(wc -l < "$ROOT/$dest/$1.lst")"
        while read -r line; do
            i=$((i + 1))
            IFS=' ' read -r a b <<< "$line"

            tput hpa "$w" el 
            echo -en " ... $i/$n"

            [ -e "$ROOT/$dest/$a" ] &&
            curl --fail-with-body -s --create-dirs -z "$ROOT/$dest/$a" -o "$ROOT/$dest/$a" "$REPO/$dest/$a" ||
            curl --fail-with-body -s --create-dirs -o "$ROOT/$dest/$a" "$REPO/$dest/$a"

            # permission
            [ -z "$b" ] || chmod "$b" "$ROOT/$dest/$a"
        done < "$ROOT/$dest/$1.lst"

        echo "" # new line
    else
        dest="prebuilts/$arch/bin/$1"
        
        info "Pull $REPO/$dest => $dest\n"

        mkdir -p "$(dirname "$ROOT/$dest")"

        [ -e "$ROOT/$dest" ] &&
        curl --fail-with-body -# -z "$ROOT/$dest" -o "$ROOT/$dest" "$REPO/$dest" ||
        curl --fail-with-body -# -o "$ROOT/$dest" "$REPO/$dest"

        chmod a+x "$ROOT/$dest"
    fi || {
        warn "Error: failed to get cmdlet $1.\n"
        return 1
    }
}

cmdlet="$(basename "$0")"

# update cmdlets.sh
if [ "$cmdlet" = "cmdlets.sh" ]; then
    info "Update $BASE => $ROOT/cmdlets.sh\n"

    # use tmpfile to avoid partial writes.
    tmpfile="/tmp/$$-cmdlets.sh"

    curl --progress-bar -o "$tmpfile" "$BASE" &&
    chmod a+x "$tmpfile" &&
    exec mv -f "$tmpfile" "$ROOT/cmdlets.sh"
fi

# update utils
case "$1" in 
    @update@)
        pull_cmdlet "$cmdlet"
        exit $? # stop here
        ;;
esac

# preapre cmdlet
[ -x "$ROOT/prebuilts/$arch/app/$cmdlet/$cmdlet" ] || 
[ -x "$ROOT/prebuilts/$arch/bin/$cmdlet" ] ||
pull_cmdlet "$cmdlet"

# full path to cmdlet
if [ -x "$ROOT/prebuilts/$arch/app/$cmdlet/$cmdlet" ]; then
    cmdlet="$ROOT/prebuilts/$arch/app/$cmdlet/$cmdlet"
else
    cmdlet="$ROOT/prebuilts/$arch/bin/$cmdlet"
fi

exec "$cmdlet" "$@"

# vim:ft=sh:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
