#!/bin/bash

set -e      # exit on error
umask 022

#export DOCKER_IMAGE=

make docker-build LIBS="$*"

# vim:ft=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
