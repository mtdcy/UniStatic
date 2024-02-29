#!/bin/bash
# GPL

upkg_url=https://download.videolan.org/pub/videolan/x264/snapshots/x264-snapshot-20190624-2245-stable.tar.bz2
upkg_sha=f29f6c3114bff735328c0091158ad03ea9f084e1bb943907fd45a8412105e324

upkg_static() {
    upkg_args=(
        --disable-avs 
        --disable-swscale 
        --disable-lavf
        --disable-ffms
        --disable-gpac 
        --disable-lsmash
        --extra-cflags=\"$CFLAGS\" 
        --extra-ldflags=\"$LDFLAGS\"
        )

    upkg_is_static && 
    upkg_args+=(--enable-static --enable-pic) ||
    upkg_args+=(--enable-shared --enable-pic --disable-static)

    AS=$NASM
    upkg_configure "${upkg_args[@]}" && 
    upkg_make_njobs install &&
    $PREFIX/bin/x264 -V 

    return $?
}
