#!/bin/bash

UPKG_DLROOT=/mnt/Service/Caches/packages
[ -d "$UPKG_DLROOT" ] || UPKG_DLROOT=""

export UPKG_DLROOT

cd "$(dirname "$0")"
. ulib.sh

_upkg_env

. "$UPKG_ROOT/libs/$1.u"

[ -z "$upkg_name" ] && upkg_name="$1" || true

_upkg_pre && _upkg_workdir

# vim:ft=sh:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
