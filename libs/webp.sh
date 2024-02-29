#!/bin/bash
#

upkg_ver=1.0.2
upkg_url=https://storage.googleapis.com/downloads.webmproject.org/releases/webp/libwebp-$upkg_ver.tar.gz
upkg_sha=3d47b48c40ed6476e8047b2ddb81d93835e0ca1b8d3e8c679afbb3004dd564b1

upkg_static() {
    rm CMakeLists.txt 

    upkg_args=(
        --disable-debug 
        --enable-libwebpdecoder 
        --enable-libwebpdemux 
        --enable-libwebpmux
    )

    upkg_is_static && 
        upkg_args+=(--enable-static --disable-shared) ||
        upkg_args+=(--enable-shared --disable-static)

    # FIXME: PNG support: no
    ulog warn "png support is not ready, fixme"

    upkg_configure "${upkg_args[@]}" &&
    upkg_make_njobs install &&
    upkg_make_test check
    return $?
}
