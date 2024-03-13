#!/bin/bash

set -e 

. "$(dirname "$0")/ulib.sh"

ulog "$1" "$2" "${@:3}"

# vim:ft=sh:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
