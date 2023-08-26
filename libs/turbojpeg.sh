#!/bin/bash
#

xpkg_ver=2.0.2
xpkg_url=https://downloads.sourceforge.net/project/libjpeg-turbo/$xpkg_ver/libjpeg-turbo-$xpkg_ver.tar.gz
xpkg_sha=acb8599fe5399af114287ee5907aea4456f8f2c1cc96d26c28aebfdf5ee82fed

xpkg_args=(
    -DREQUIRE_SIMD=TRUE 
    -DWITH_JPEG8=1
    -DENABLE_SHARED=TRUE 
    -DENABLE_STATIC=TRUE
)

xpkg_static() {
    xpkg_configure "${xpkg_args[@]}" -DENABLE_SHARED=FALSE &&
    xpkg_make_njobs install
    # TODO: test
    return $?
}
