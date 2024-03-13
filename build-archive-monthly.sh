#!/bin/bash

set -e      # exit on error
umask 022

export ULOG_VERBOSE=0

cd "$(dirname "$0")"
. ulib.sh

LIBS=(
    # utils
    coreutils gsed gawk grep gmake
    # editor
    neovim
    # net
    wget
    # multimedia
    ffmpeg6 ffmpeg4 mac
    # misc
    neofetch
)

export LIBS="${LIBS[@]}"
export NJOBS=8

ulog info "Build ($LIBS) with $NJOBS jobs ..."

#1. macOS
( 
    # start subshell for remote
    export REMOTE_HOST=10.10.10.234
    export REMOTE_WORKDIR="~/UniStatic" # don't expand '~' here

    ulog info "Start remote build @ $REMOTE_HOST:$REMOTE_WORKDIR ..."

    make remote-clean && 
    make remote-build LIBS="$LIBS"&& 
    make pull-remote  
) 2>&1 > macos.log &

# docker cann't run in background 
{
    ulog info "Start docker build ..."
    make docker-clean && 
    make docker-build LIBS="$LIBS"
} 2>&1 > docker.log

# wait for remote
ulog info ".Wait for remote build(s) ..."
wait

# install DEST
export HOST= 
export DEST=/mnt/Service/Downloads/public/UniStatic/current

ulog info "Install prebuilts to $HOST:$DEST ..."
make install

# vim:ft=sh:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
