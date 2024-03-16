#!/bin/bash
[ -z $BASH ] && exec bash "$0" "$@"

# source ulib.sh 
cd "$(dirname "$0")"
. ulib.sh

echo "upkg njobs    : $UPKG_NJOBS"
echo "ulog mode     : $ULOG_MODE"

#make test-tty

upkg_build "$@"

# vim:ft=sh:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
