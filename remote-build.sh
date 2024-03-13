#!/bin/bash

set -e      # exit on error
umask 022

#export REMOTE_HOST=
#export REMOTE_WORKDIR=

make remote-build LIBS="$*" &&
make pull-remote

# vim:ft=sh:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
