#!/bin/bash

set -e 
LANG=C.UTF-8
LC_ALL=$LANG

ROOT="$(realpath "$(dirname "$0")")"
BASE=https://git.mtdcy.top:8443/mtdcy/UniStatic/raw/branch/main/cmdlets.sh
REPO=https://pub.mtdcy.top:8443/UniStatic/current

info() { echo -ne "\\033[32m$*\\033[39m"; }
warn() { echo -ne "\\033[33m$*\\033[39m"; }

case "$OSTYPE" in
    linux-gnu)  arch="$(uname -m)-linux-gnu"            ;;
    darwin*)    arch="$(uname -m)-apple-darwin"         ;;
    *)          warn "unknown OSTYPE $OSTYPE.\n"; exit 1;;
esac

# pull cmdlet from server
pull_cmdlet() {
    # common options
    wget+=" -q --show-progress"

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

            curl --fail-with-body -s --create-dirs -o "$ROOT/$dest/$a" "$REPO/$dest/$a"
            # permission
            [ -z "$b" ] || chmod "$b" "$ROOT/$dest/$a"
        done < "$ROOT/$dest/$1.lst"

        echo "" # new line
    else
        dest="prebuilts/$arch/bin/$1"
        
        info "Pull $REPO/$dest => $dest\n"

        mkdir -p "$(dirname "$ROOT/$dest")"

        curl --fail-with-body -# -o "$ROOT/$dest" "$REPO/$dest"

        chmod a+x "$ROOT/$dest"
    fi || {
        warn "Error: failed to get cmdlet $1.\n"
        return 1
    }
}

cmdlet="$(basename "$0")"

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

# upgrade & update
case "$1" in 
    @update@)
        rm -f "$cmdlet" || true
        pull_cmdlet
        exit $? # stop here
        ;;
    @upgrade@)
        # find out real name
        real="$(basename "$(readlink -f "$0")")"

        # update all cmdlet(s), ignore failure
        find "$(dirname "$0")"/ -type l -lname "$real" -exec {} @update@ \; || true

        # update and replace self.
        info "Pull $BASE => $real\n"
        tmpfile="/tmp/$$-$real"
        curl --progress-bar -o "$tmpfile" "$BASE" &&
        chmod a+x "$tmpfile" &&
        exec mv -f "$tmpfile" "$real"
        ;;
esac

exec "$cmdlet" "$@"

# vim:ft=sh:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
