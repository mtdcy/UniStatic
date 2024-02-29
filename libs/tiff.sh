#!/bin/bash
#

upkg_ver=4.0.10
upkg_url=https://download.osgeo.org/libtiff/tiff-$upkg_ver.tar.gz
upkg_sha=2c52d11ccaf767457db0c46795d9c7d1a8d8f76f68b0b800a3dfe45786b996e4

upkg_static() {
    # force configure 
    rm CMakeLists.txt 

    upkg_args=(
        --disable-debug 
        --disable-webp
        --enable-lzma
        --disable-webp     # loop dependency between tiff & webp
        --disable-zstd
        --enable-static 
        --disable-shared
    )

    upkg_is_static && 
    upkg_args+=(--enable-static) ||
    upkg_args+=(--enable-shared --enable-rpath)

    upkg_configure "${upkg_args[@]}" &&
    upkg_make_njobs install
    return $?
}
