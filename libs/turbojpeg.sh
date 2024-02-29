#!/bin/bash
#

upkg_ver=2.0.2
upkg_url=https://downloads.sourceforge.net/project/libjpeg-turbo/$upkg_ver/libjpeg-turbo-$upkg_ver.tar.gz
upkg_sha=acb8599fe5399af114287ee5907aea4456f8f2c1cc96d26c28aebfdf5ee82fed

upkg_args=(
    -DREQUIRE_SIMD=TRUE 
    -DWITH_JPEG8=1
    -DENABLE_SHARED=TRUE 
    -DENABLE_STATIC=TRUE
)

upkg_static() {
    upkg_configure "${upkg_args[@]}" -DENABLE_SHARED=FALSE &&
    upkg_make_njobs install
    # TODO: test
    return $?
}
