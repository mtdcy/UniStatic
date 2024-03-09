#!/bin/bash
# General-purpose data compression with high compression ratio

upkg_lic="BSD"
upkg_ver=5.6.0
upkg_url=https://github.com/tukaani-project/xz/releases/download/v$upkg_ver/xz-$upkg_ver.tar.gz
upkg_sha=0f5c81f14171b74fcc9777d302304d964e63ffc2d7b634ef023a7249d9b5d875

upkg_args=(
    --disable-option-checking
    --enable-silent-rules
    --disable-nls
    --disable-debug
    --disable-shared 
    --enable-static
)

upkg_static() {
    rm CMakeLists.txt # force use configure 

    upkg_configure && upkg_make_njobs && upkg_make install && upkg_make_test check
}
