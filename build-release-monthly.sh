#!/bin/bash

set -e      # exit on error
umask 022

LIBS=(
    # utils
    coreutils gsed gawk grep
    # multimedia
    ffmpeg6 ffmpeg4 mac
    # editor
    neovim
    # misc
    neofetch
)

export LIBS="${LIBS[@]}"
export NJOBS=4

# start subshell for remote

#1. macOS
( 
    export REMOTE_HOST=10.10.10.234
    export REMOTE_WORKDIR="~/UniStatic" # don't expand '~' here
    make clean-remote && make libs-remote && make pull-remote  
) &> macos.log &

# docker cann't run in background 
make clean-docker && make libs-docker &> docker.log

# wait for remote
wait

# install DEST
export HOST= 
export DEST=/mnt/Service/Downloads/public/UniStatic

make install

# vim:ft=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
