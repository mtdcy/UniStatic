#!/bin/bash

xpkg_lic=""
xpkg_ver=2.0.9
xpkg_url=https://libsdl.org/release/SDL2-$xpkg_ver.tar.gz
xpkg_sha=255186dc676ecd0c1dbf10ec8a2cc5d6869b5079d8a38194c2aecdff54b324b1

xpkg_static() {
    rm CMakeLists.txt 

    xpkg_args=(
        --without-x
        --enable-shared 
        --enable-rpath
        --enable-static 
        )

    xpkg_configure "${xpkg_args[@]}" --disable-shared && 
    xpkg_make_njobs install 
    return $?
}

