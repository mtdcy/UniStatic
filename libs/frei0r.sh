#!/bin/bash
# GPL

xpkg_lic="GPL"
xpkg_ver=1.6.1
xpkg_url=https://files.dyne.org/frei0r/releases/frei0r-plugins-$xpkg_ver.tar.gz
xpkg_sha=e0c24630961195d9bd65aa8d43732469e8248e8918faa942cfb881769d11515e

# always build shared lib 
xpkg_shared() {

    # both build system has its faults, so use differ to host os
    if xpkg_is_msys; then
        # use cmake
        xpkg_configure && xpkg_make_njobs install 
    else 
        rm CMakeLists.txt # force configure 
        xpkg_args=(
            --disable-debug 
            --enable-shared 
            --enable-pic 
            )

        xpkg_configure "${xpkg_args[@]}" && 
        xpkg_make_njobs install 
    fi

    return $?
}

