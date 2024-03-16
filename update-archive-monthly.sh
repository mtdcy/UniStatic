#!/bin/bash

exec > >(logger -t $(basename $0))
exec 2> >(logger -t $(basename $0) -p user.error)
echo "=="

cd "$(dirname "$0")"
. ulib.sh

# ENVs
export UPKG_NJOBS=4
export ULOG_MODE=plain  # don't use tty in background
#export UPKG_STRICT=0    # non-strict mode for quick test.

ulog info "Build with $UPKG_NJOBS jobs ..."
    
[ "$UPKG_STRICT" -ne 0 ] && rm -rf out prebuilts || true

PIDs=()

#1. macOS
(   
    unset DOCKER_IMAGE
    # start subshell for remote
    export REMOTE_HOST=10.10.10.234
    export REMOTE_WORKDIR="~/UniStatic" # don't expand '~' here

    unset UPKG_NJOBS= # macos is much slow than host => use all cores.

    ulog info "Start remote build @ $REMOTE_HOST:$REMOTE_WORKDIR ..."

    #make prepare-remote-homebrew
    [ "$UPKG_STRICT" -ne 0 ] && make distclean || true

    make all &>macos.log
) &
PIDs+=($!)

#2. docker
(   
    unset REMOTE_HOST
    export DOCKER_IMAGE="mtdcy/unistatic"

    ulog info "Start docker build @ $DOCKER_IMAGE ..."

    [ "$UPKG_STRICT" -ne 0 ] && make distclean || true

    #make prepare-docker-image &&
    make all &>docker.log
) &
PIDs+=($!)

# wait for remote
#wait "${PIDs[@]}"
while [ "$(waitpid --timeout 300 -e "${PIDs[@]}")" -ne 0 ]; do
    ulog info "Wait for remote/docker build(s) ..."
done

# install DEST
export HOST=
export DEST=/mnt/Service/Downloads/public/UniStatic/current

ulog info "Install prebuilts to $HOST:$DEST ..."
make install &> install.log

echo "=="

# vim:ft=sh:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
