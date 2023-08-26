#!/bin/bash
# Old MIT
# for libass

xpkg_lic="MIT"
xpkg_ver=2.4.0
xpkg_url=https://github.com/harfbuzz/harfbuzz/releases/download/$xpkg_ver/harfbuzz-$xpkg_ver.tar.bz2
xpkg_sha=b470eff9dd5b596edf078596b46a1f83c179449f051a469430afc15869db336f

xpkg_static() {
    rm CMakeLists.txt 

    xpkg_args=(
        --disable-debug
        --enable-shared
        --enable-static
        )

    xpkg_configure "${xpkg_args[@]}" --disable-shared &&
    xpkg_make_njobs install
    return $?
}

