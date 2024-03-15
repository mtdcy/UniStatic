#!/bin/bash

UPKG_DLROOT=/mnt/Service/Caches/packages
[ -d "$UPKG_DLROOT" ] || UPKG_DLROOT=""

export UPKG_DLROOT

cd "$(dirname "$0")"
. ulib.sh

upkg_env_setup

. "$UPKG_ROOT/libs/$1.u"

[ -z "$upkg_zip" ] && upkg_zip="$(basename $upkg_url)"

upkg_zip="$UPKG_DLROOT/$upkg_zip"

upkg_get "$upkg_url" "$upkg_sha" "$upkg_zip" &&
upkg_unzip "$upkg_zip"

# vim:ft=sh:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
