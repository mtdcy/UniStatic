#!/bin/bash

set -e 

. "$(dirname "$0")/ulib.sh"

ulog "$1" "${@:2}"

# vim:ft=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
