#!/bin/bash
# Library for manipulating PNG images

upkg_lic="libpng-2.0"
upkg_ver=1.6.43
upkg_url=https://downloads.sourceforge.net/libpng/libpng16/libpng-$upkg_ver.tar.xz
upkg_sha=6a5ca0652392a2d7c9db2ae5b40210843c0bbc081cbd410825ab00cc59f14a6c
upkg_dep=(zlib)

upkg_args=(
    --disable-dependency-tracking
    --disable-silent-rules
    --enable-hardware-optimizations 
    --enable-unversioned-links
    --enable-unversioned-libpng-pc
    --disable-shared 
    --enable-static
)

upkg_static() {
    # force configure 
    rm CMakeLists.txt

    upkg_configure && upkg_make_njobs install install-libpng-pc install-libpng-config  && upkg_make_test
}
