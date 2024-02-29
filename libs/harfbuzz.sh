#!/bin/bash
# Old MIT
# for libass

upkg_lic="MIT"
upkg_ver=2.4.0
upkg_url=https://github.com/harfbuzz/harfbuzz/releases/download/$upkg_ver/harfbuzz-$upkg_ver.tar.bz2
upkg_sha=b470eff9dd5b596edf078596b46a1f83c179449f051a469430afc15869db336f

upkg_static() {
    rm CMakeLists.txt 

    upkg_args=(
        --disable-debug
        --enable-shared
        --enable-static
        )

    upkg_configure "${upkg_args[@]}" --disable-shared &&
    upkg_make_njobs install
    return $?
}

