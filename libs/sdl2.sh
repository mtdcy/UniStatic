#!/bin/bash

upkg_lic=""
upkg_ver=2.0.9
upkg_url=https://libsdl.org/release/SDL2-$upkg_ver.tar.gz
upkg_sha=255186dc676ecd0c1dbf10ec8a2cc5d6869b5079d8a38194c2aecdff54b324b1

upkg_static() {
    rm CMakeLists.txt 

    upkg_args=(
        --without-x
        --enable-shared 
        --enable-rpath
        --enable-static 
        )

    upkg_configure "${upkg_args[@]}" --disable-shared && 
    upkg_make_njobs install 
    return $?
}

