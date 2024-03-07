#!/bin/bash
# JPEG image codec that aids compression and decompression

upkg_lic="IJG"
upkg_ver=3.0.1
upkg_url=https://downloads.sourceforge.net/project/libjpeg-turbo/$upkg_ver/libjpeg-turbo-$upkg_ver.tar.gz
upkg_sha=22429507714ae147b3acacd299e82099fce5d9f456882fc28e252e4579ba2a75
upkg_dep=()

upkg_args=(
    -DREQUIRE_SIMD=TRUE 
    -DWITH_JPEG8=1
    -DENABLE_SHARED=FALSE
    -DENABLE_STATIC=TRUE
)

upkg_static() {
    upkg_configure && upkg_make_njobs install
}
