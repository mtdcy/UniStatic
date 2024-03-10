#!/bin/bash
[ -z $BASH ] && exec bash "$0" "$@"

#set -x
set -e      # exit on error
umask 022

# source ulib.sh 
source "$(dirname $0)/ulib.sh"

upkg_build_deps "$@"
