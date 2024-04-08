#!/bin/bash

set -eo pipefail

exec > >(logger -t $(basename $0))
exec 2> >(logger -t $(basename $0) -p user.error)
echo "=="
echo "PATH:$PATH"

cd "$(dirname "$0")"

# ENVs
export UPKG_NJOBS=4
export ULOG_MODE=plain  # don't use tty in background
#export UPKG_STRICT=0    # non-strict mode for quick test.

# ARCHs
ARCHs=(
    x86_64-apple-darwin
    x86_64-linux-gnu
)

echo "Build with $UPKG_NJOBS jobs ..."

[ "$UPKG_STRICT" -eq 0 ] || rm -rf out prebuilts

PIDs=()

#1. macOS - x86_64-apple-darwin
(
    rm -fv prebuilts/x86_64-apple-darwin/release
    set -eo pipefail
    exec &> macos.log

    unset DOCKER_IMAGE
    # start subshell for remote
    export REMOTE_HOST=10.10.10.234
    export REMOTE_WORKDIR="~/UniStatic" # don't expand '~' here

    unset UPKG_NJOBS # macos is much slow than host => use all cores.

    echo "Start remote build @ $REMOTE_HOST:$REMOTE_WORKDIR ..."

    [ "$UPKG_STRICT" -eq 0 ] || make distclean

    #make prepare-remote-homebrew
    make all

    # set return value
    date '+%Y.%m.%d' > prebuilts/x86_64-apple-darwin/release
) &
PIDs+=($!)

#2. docker - x86_64-linux-gnu
(
    rm -fv prebuilts/x86_64-linux-gnu/release
    set -eo pipefail
    exec &> docker.log

    unset REMOTE_HOST
    export DOCKER_IMAGE="unistatic/ubuntu"

    echo "Start docker build @ $DOCKER_IMAGE ..."

    [ "$UPKG_STRICT" -eq 0 ] || make distclean

    #make prepare-docker-image &&
    make all

    # set return value
    date '+%Y.%m.%d' > prebuilts/x86_64-linux-gnu/release
) &
PIDs+=($!)

# wait for remote/docker to start
sleep 3

# wait for remotes
#  => bash:wait may not exit after children terminated.
echo "Wait for remote/docker build(s) ${PIDs[*]} ..."
wait "${PIDs[@]}" || true
echo "Remote/Docker build(s) completed ..."

DEST="/mnt/Service/Downloads/public/UniStatic/$(date '+%Y.%m.%d')"
mkdir -pv "$DEST"

# create latest link
latest="$(dirname "$DEST")/latest"
rm -fv "$latest"
ln -sfv "$DEST" "$latest"

for arch in "${ARCHs[@]}"; do
    if [ -e prebuilts/$arch/release ]; then
        echo "Install $arch => $DEST ..."
        rsync -ac "prebuilts/$arch/" "$DEST/$arch/"
    else
        echo "Build for $arch failed?"
    fi
done

echo "=="

# vim:ft=sh:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
