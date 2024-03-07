#!/bin/bash
# Image format providing lossless and lossy compression for web images

upkg_lic="BSD-3-Clause"
upkg_ver=1.3.2
upkg_url=https://storage.googleapis.com/downloads.webmproject.org/releases/webp/libwebp-$upkg_ver.tar.gz
upkg_sha=2a499607df669e40258e53d0ade8035ba4ec0175244869d1025d460562aa09b4
upkg_dep=(png gif tiff turbojpeg)

upkg_args=(
    --disable-debug 
    --enable-libwebpdecoder 
    --enable-libwebpdemux 
    --enable-libwebpmux
    --disable-shared
    --enable-static
)

upkg_static() {
    rm CMakeLists.txt 

    upkg_configure && upkg_make_njobs install && upkg_make_test check
}
