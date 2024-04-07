#!/bin/bash

UPKG_DLROOT=/mnt/Service/Caches/packages
[ -d "$UPKG_DLROOT" ] || UPKG_DLROOT=""

export UPKG_DLROOT

cd "$(dirname "$0")"
. ulib.sh

upkg_env_setup || true

. "$UPKG_ROOT/libs/$1.u"

mkdir -p "$UPKG_WORKDIR/$1-$upkg_ver"
cd "$UPKG_WORKDIR/$1-$upkg_ver"

upkg_prepare

ulog info ".Path" "$PWD"

# vim:ft=sh:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
