#!/bin/bash

upkg_lic="Zlib"
upkg_ver=2.30.1
upkg_url=https://github.com/libsdl-org/SDL/releases/download/release-$upkg_ver/SDL2-$upkg_ver.tar.gz
upkg_sha=01215ffbc8cfc4ad165ba7573750f15ddda1f971d5a66e9dcaffd37c587f473a

upkg_static() {
    rm CMakeLists.txt 

    upkg_args=(
        --disable-option-checking
        --disable-dependency-tracking
        --without-x
        --enable-libiconv
        --disable-shared 
        --enable-static 
        )

    upkg_configure && upkg_make_njobs && upkg_make install 
}

