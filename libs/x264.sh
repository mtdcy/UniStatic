#!/bin/bash
# GPL

xpkg_url=https://download.videolan.org/pub/videolan/x264/snapshots/x264-snapshot-20190624-2245-stable.tar.bz2
xpkg_sha=f29f6c3114bff735328c0091158ad03ea9f084e1bb943907fd45a8412105e324

xpkg_static() {
    xpkg_args=(
        --disable-avs 
        --disable-swscale 
        --disable-lavf
        --disable-ffms
        --disable-gpac 
        --disable-lsmash
        --extra-cflags=\"$CFLAGS\" 
        --extra-ldflags=\"$LDFLAGS\"
        )

    xpkg_is_static && 
    xpkg_args+=(--enable-static) ||
    xpkg_args+=(--enable-shared --enable-pic --disable-static)

    AS=$NASM
    xpkg_configure "${xpkg_args[@]}" && 
    xpkg_make_njobs install &&
    $PREFIX/bin/x264 -V 

    return $?
}
