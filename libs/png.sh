#!/bin/bash

upkg_ver=1.6.37
upkg_url=https://downloads.sourceforge.net/libpng/libpng-$upkg_ver.tar.xz
upkg_sha=505e70834d35383537b6491e7ae8641f1a4bed1876dbfe361201fc80868d88ca

upkg_args=(
    --enable-hardware-optimizations 
    --enable-unversioned-links
    --enable-unversioned-libpng-pc
    --enable-shared 
    --enable-static
)

upkg_static() {
    # force configure 
    rm CMakeLists.txt

    upkg_configure "${upkg_args[@]}" --disable-shared &&
    upkg_make_njobs install install-libpng-pc install-libpng-config  &&
    upkg_make_test
    return $?
}
