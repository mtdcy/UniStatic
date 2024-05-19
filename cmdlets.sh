#!/bin/bash

set -eo pipefail
export LANG=C LC_CTYPE=UTF-8

#ROOT="$(dirname "$(realpath "$0")")"
ROOT="$(dirname "$0")"
# => no realpath on macOS by default

BASE=https://git.mtdcy.top:8443/mtdcy/UniStatic/raw/branch/main/cmdlets.sh
REPO=https://pub.mtdcy.top:8443/UniStatic/current

case "$OSTYPE" in
    darwin*)    ARCH="$(uname -m)-apple-darwin" ;;
    *)          ARCH="$(uname -m)-$OSTYPE"      ;;
esac
ARCH=${CMDLETS_ARCH:-$ARCH}     # accept ENV:CMDLETS_ARCH

usage() {
    cat << EOF
$(basename "$BASE") action [parameter(s)]

Supported actions:
    upgrade             - self update.
    install <cmdlet>    - install cmdlet.
    update  <cmdlet>    - update cmdlet.
EOF
}

error() { echo -ne "\\033[31m$*\\033[39m"; }
info()  { echo -ne "\\033[32m$*\\033[39m"; }
warn()  { echo -ne "\\033[33m$*\\033[39m"; }

# pull cmdlet from server
pull() {
    # cmdlet? 
    #  => prefer cmdlet instead of applet.
    local dest="prebuilts/$ARCH/bin/$1"
    if curl --fail -s -o /dev/null -I "$REPO/$dest"; then
        dest="prebuilts/$ARCH/bin/$1"
        
        info "Pull $1 => $dest\n"

        mkdir -p "$(dirname "$ROOT/$dest")"

        [ -e "$ROOT/$dest" ] &&
        curl --fail -# -z "$ROOT/$dest" -o "$ROOT/$dest" "$REPO/$dest" ||
        curl --fail -# -o "$ROOT/$dest" "$REPO/$dest"

        chmod a+x "$ROOT/$dest"
        return
    else
        # cmdlet => applet?
        rm -f "$ROOT/$dest"
    fi

    # applet?
    local dest="prebuilts/$ARCH/app/$1"
    if curl --fail -s -o /dev/null -I "$REPO/$dest/$1.tar.gz"; then
        # get app.tar.gz
        info "Pull $1 => $dest\n"
        curl --fail -# -o "/tmp/$$_$1.tar.gz" "$REPO/$dest/$1.tar.gz"
        mkdir -p "$ROOT/$dest"
        tar -C "$ROOT/$dest" -xf /tmp/$$_$1.tar.gz
        rm /tmp/$$_$1.tar.gz
    elif curl --fail -s -o "/tmp/$$_$1.lst" "$REPO/$dest/$1.lst"; then
        # get app.lst
        mkdir -p "$ROOT/$dest" && 
        mv "/tmp/$$_$1.lst" "$ROOT/$dest/$1.lst" &&

        tput hpa 0 el 
        local message="Pull $1 => $dest"

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
            curl --fail -s --create-dirs -z "$ROOT/$dest/$a" -o "$ROOT/$dest/$a" "$REPO/$dest/$a" ||
            curl --fail -s --create-dirs -o "$ROOT/$dest/$a" "$REPO/$dest/$a"

            # permission
            [ -z "$b" ] || chmod "$b" "$ROOT/$dest/$a"
        done < "$ROOT/$dest/$1.lst"

        echo "" # new line
        rm /tmp/$$_$1.lst
    else
        error "Error: failed to get cmdlet $1.\n"
        return 1
    fi
}

name="$(basename "$0")"

# update cmdlets.sh
if [ "$name" = "$(basename "$BASE")" ]; then
    case "$1" in
        upgrade)
            info "Update $name => $ROOT/cmdlets.sh\n"
            # use tmpfile to avoid partial writes.
            tmpfile="/tmp/$$-cmdlets.sh"
            curl --fail -# -o "$tmpfile" "$BASE"
            chmod a+x "$tmpfile"
            exec mv -f "$tmpfile" "$ROOT/cmdlets.sh"
            ;;
        install|update)
            [ -n "$2" ] || { usage; exit; }
            pull "$2"
            ln -sf "$name" "$ROOT/$2"
            ;;
        help|*)
            usage
            ;;
    esac
    exit
fi

# preapre cmdlet
cmdlet="$ROOT/prebuilts/$ARCH/app/$name/$name"
[ -x "$cmdlet" ] || cmdlet="$ROOT/prebuilts/$ARCH/bin/$name"
[ -x "$cmdlet" ] || pull "$name"

# exec cmdlet
cmdlet="$ROOT/prebuilts/$ARCH/app/$name/$name"
[ -x "$cmdlet" ] || cmdlet="$ROOT/prebuilts/$ARCH/bin/$name"
[ -x "$cmdlet" ] || error "no cmdlet $name found.\n"

exec "$cmdlet" "$@"

# vim:ft=sh:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
