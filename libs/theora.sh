#!/bin/bash
# BSD 3-Clause

upkg_ver=1.1.1
upkg_url=https://downloads.xiph.org/releases/theora/libtheora-$upkg_ver.tar.bz2
upkg_sha=b6ae1ee2fa3d42ac489287d3ec34c5885730b1296f0801ae577a35193d3affbc

upkg_static() {
    upkg_args=(
        --disable-examples 
        --disable-oggtest 
        --disable-vorbistest 
        --with-ogg=$PREFIX
        --with-vorbis=$PREFIX
        )

    upkg_is_static && 
        upkg_args+=(--enable-static --disable-shared) ||
        upkg_args+=(--enable-shared --disable-static)

    upkg_configure "${upkg_args[@]}" &&
    upkg_make_njobs install &&
    upkg_make_test 
    return $?
}
