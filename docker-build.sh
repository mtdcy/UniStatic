#!/bin/bash

set -e      # exit on error
umask 022

make libs-docker LIBS="$*"
