#!/bin/bash

set -e 
LANG=C.UTF-8
LC_ALL=$LANG

BASE=https://git.mtdcy.top:8443/mtdcy/UniStatic/raw/branch/main/cmdlets.sh
REPO=https://pub.mtdcy.top:8443/UniStatic/current/prebuilts

cmdlet="$(basename "$0")"

info() { echo -e "\\033[32m$*\\033[39m"; }
warn() { echo -e "\\033[33m$*\\033[39m"; }

case "$OSTYPE" in
    linux-gnu)  arch="$(uname -m)-linux-gnu"            ;;
    darwin*)    arch="$(uname -m)-apple-darwin"         ;;
    *)          warn "unknown OSTYPE $OSTYPE."; exit 1  ;;
esac

# full path to cmdlet
cmdlet="$(dirname "$0")/prebuilts/$arch/bin/$cmdlet"

# pull cmdlet from server
pull_cmdlet() {
    url="$REPO${cmdlet##*prebuilts}"

    info "Pull $url => $cmdlet"
    mkdir -p "$(dirname "$cmdlet")" && 
    # wget not available on macOS by default
    curl --progress-bar -o "$cmdlet" "$url" || {
        warn "Error: failed to get cmdlet $(basename "$cmdlet")"
        return 1
    }
    chmod a+x "$cmdlet"
}

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
        info "Pull $BASE => $real"
        tmpfile="/tmp/$$-$real"
        curl --progress-bar -o "$tmpfile" "$BASE" &&
        chmod a+x "$tmpfile" &&
        exec mv -f "$tmpfile" "$real"
        ;;
esac

[ -x "$cmdlet" ] || pull_cmdlet

exec "$cmdlet" "$@"

# vim:ft=sh:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
