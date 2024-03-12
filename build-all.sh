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

{ 
    make libs-remote && 
    make pull-remote  
} &> remote.log &
# docker cann't run in background 
make libs-docker &> docker.log

wait

make update
