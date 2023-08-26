#!/bin/bash

xpkg_ver=1.6.37
xpkg_url=https://downloads.sourceforge.net/libpng/libpng-$xpkg_ver.tar.xz
xpkg_sha=505e70834d35383537b6491e7ae8641f1a4bed1876dbfe361201fc80868d88ca

xpkg_args=(
    --enable-hardware-optimizations 
    --enable-unversioned-links
    --enable-unversioned-libpng-pc
    --enable-shared 
    --enable-static
)

xpkg_static() {
    # force configure 
    rm CMakeLists.txt

    xpkg_configure "${xpkg_args[@]}" --disable-shared &&
    xpkg_make_njobs install install-libpng-pc install-libpng-config  &&
    xpkg_make_test
    return $?
}
