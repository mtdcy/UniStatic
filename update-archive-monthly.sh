#!/bin/bash

exec > >(logger -t $(basename $0))
exec 2> >(logger -t $(basename $0) -p user.error)
echo "=="

export ULOG_VERBOSE=0

cd "$(dirname "$0")"
. ulib.sh

# ENVs
export UPKG_NJOBS=8
export ULOG_MODE=plain

ulog info "Build with $NJOBS jobs ..."

rm -rf out prebuilts || true

#1. macOS
( 
    unset DOCKER_IMAGE
    # start subshell for remote
    export REMOTE_HOST=10.10.10.234
    export REMOTE_WORKDIR="~/UniStatic" # don't expand '~' here

    ulog info "Start remote build @ $REMOTE_HOST:$REMOTE_WORKDIR ..."

    #make prepare-remote-homebrew
    { make distclean && make all; } &> macos.log
) &

# docker cann't run in background 
(
    unset REMOTE_HOST
    export DOCKER_IMAGE="mtdcy/unistatic"

    ulog info "Start docker build @ $DOCKER_IMAGE ..."

    #make prepare-docker-image &&
    { make distclean && make all; } &> docker.log
) &

# wait for remote
ulog info "Wait for remote build(s) ..."
wait

# install DEST
export HOST= 
export DEST=/mnt/Service/Downloads/public/UniStatic/current

ulog info "Install prebuilts to $HOST:$DEST ..."
make install

echo "=="

# vim:ft=sh:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
