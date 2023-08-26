#!/bin/bash
#

xpkg_ver=4.0.10
xpkg_url=https://download.osgeo.org/libtiff/tiff-$xpkg_ver.tar.gz
xpkg_sha=2c52d11ccaf767457db0c46795d9c7d1a8d8f76f68b0b800a3dfe45786b996e4

xpkg_static() {
    # force configure 
    rm CMakeLists.txt 

    xpkg_args=(
        --disable-debug 
        --disable-webp
        --enable-lzma
        --disable-webp     # loop dependency between tiff & webp
        --disable-zstd
        --enable-static 
    )

    xpkg_is_static && 
    xpkg_args+=(--enable-static) ||
    xpkg_args+=(--enable-shared --enable-rpath)

    xpkg_configure "${xpkg_args[@]}" &&
    xpkg_make_njobs install
    return $?
}
