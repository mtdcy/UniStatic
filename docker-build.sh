#!/bin/bash

set -e      # exit on error
umask 022

#export DOCKER_IMAGE=

make libs-docker LIBS="$*"
