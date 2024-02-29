#!/bin/bash
# GPL

upkg_lic="GPL"
upkg_ver=1.6.1
upkg_url=https://files.dyne.org/frei0r/releases/frei0r-plugins-$upkg_ver.tar.gz
upkg_sha=e0c24630961195d9bd65aa8d43732469e8248e8918faa942cfb881769d11515e

# always build shared lib 
upkg_static() {

    # both build system has its faults, so use differ to host os
    if upkg_msys; then
        # use cmake
        upkg_configure && upkg_make_njobs install 
    else 
        rm CMakeLists.txt # force configure 
        upkg_args=(
            --disable-debug 
            --enable-shared 
            --enable-pic 
        )

        upkg_configure "${upkg_args[@]}" && 
        upkg_make_njobs install 
    fi

    return $?
}

