#!/bin/bash

set -e      # exit on error
umask 022

#export REMOTE_HOST=
#export REMOTE_WORKDIR=

make libs-remote LIBS="$*" &&
make pull-remote
