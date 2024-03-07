#!/bin/bash
# TIFF library and utilities

upkg_lic="libtiff"
upkg_ver=4.6.0
upkg_url=https://download.osgeo.org/libtiff/tiff-$upkg_ver.tar.gz
upkg_sha=88b3979e6d5c7e32b50d7ec72fb15af724f6ab2cbf7e10880c360a77e4b5d99a
upkg_dep=(zlib lzma turbojpeg zstd)

upkg_args=(
    --disable-dependency-tracking
    --disable-debug 
    --disable-webp
    --enable-lzma
    --enable-zstd
    --disable-webp     # loop dependency between tiff & webp
    --disable-shared
    --enable-static
    --without-x
)

upkg_static() {
    # force configure 
    rm CMakeLists.txt 

    upkg_configure && upkg_make_njobs install
}
