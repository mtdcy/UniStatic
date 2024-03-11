#!/bin/bash

set -e 
LANG=C.UTF-8
LC_ALL=$LANG
URL=https://pub.mtdcy.top:8443/UniStatic/current/prebuilts

cmdlet="$(basename "$0")"

info() { echo -e "\\033[32m$*\\033[39m"; }
warn() { echo -e "\\033[33m$*\\033[39m"; }

case "$OSTYPE" in
    linux-gnu)
        arch="$(uname -m)-linux-gnu"
        ;;
    darwin*)
        arch="$(uname -m)-apple-darwin"
        ;;
    *)
        warn "FIXME, unknown OSTYPE $OSTYPE."
        exit 1
        ;;
esac

cmdlet="$(dirname "$0")/prebuilts/$arch/bin/$cmdlet"

[ -e "$cmdlet" ] || {
    url="$URL${cmdlet##*prebuilts}"

    info "Pull cmdlet $(basename "$cmdlet") from $url."
    mkdir -p "$(dirname "$cmdlet")" && 
    wget --quiet --show-progress "$url" -O "$cmdlet" || {
        warn "Error: failed to get cmdlet $(basename "$cmdlet")"
        exit 1
    }
    chmod a+x "$cmdlet"
}

exec "$cmdlet" "$@"
