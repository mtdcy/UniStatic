#!/bin/bash

set -e      # exit on error
umask 022

export LIBS="ffmpeg4 ffmpeg6 mac" 

{ 
    make libs-remote && 
    make pull-remote  
} &> remote.log &
# docker cann't run in background 
make libs-docker &> docker.log

wait

make update
