#!/bin/bash
# BSD 3-Clause

xpkg_ver=1.1.1
xpkg_url=https://downloads.xiph.org/releases/theora/libtheora-$xpkg_ver.tar.bz2
xpkg_sha=b6ae1ee2fa3d42ac489287d3ec34c5885730b1296f0801ae577a35193d3affbc

xpkg_static() {
    xpkg_args=(
        --disable-examples 
        --disable-oggtest 
        --disable-vorbistest 
        --with-ogg=$PREFIX
        --with-vorbis=$PREFIX
        )

    xpkg_is_static && 
        xpkg_args+=(--enable-static --disable-shared) ||
        xpkg_args+=(--enable-shared --disable-static)

    xpkg_configure "${xpkg_args[@]}" &&
    xpkg_make_njobs install &&
    xpkg_make_test 
    return $?
}
