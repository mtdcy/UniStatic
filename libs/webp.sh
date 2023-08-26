#!/bin/bash
#

xpkg_ver=1.0.2
xpkg_url=https://storage.googleapis.com/downloads.webmproject.org/releases/webp/libwebp-$xpkg_ver.tar.gz
xpkg_sha=3d47b48c40ed6476e8047b2ddb81d93835e0ca1b8d3e8c679afbb3004dd564b1

xpkg_static() {
    rm CMakeLists.txt 

    xpkg_args=(
        --disable-debug 
        --enable-libwebpdecoder 
        --enable-libwebpdemux 
        --enable-libwebpmux
    )

    xpkg_is_static && 
        xpkg_args+=(--enable-static --disable-shared) ||
        xpkg_args+=(--enable-shared --disable-static)

    # FIXME: PNG support: no
    xlog warn "png support is not ready, fixme"

    xpkg_configure "${xpkg_args[@]}" &&
    xpkg_make_njobs install &&
    xpkg_make_test check
    return $?
}
