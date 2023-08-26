#!/bin/bash
# 

xpkg_lic="LGPL"
xpkg_ver=1.15
xpkg_url=https://ftp.gnu.org/pub/gnu/libiconv/libiconv-$xpkg_ver.tar.gz
xpkg_sha=ccf536620a45458d26ba83887a983b96827001e92a13847b45e4925cc8913178

xpkg_static() {
    xpkg_args=(
        --disable-debug 
        --enable-extra-encodings 
        --enable-shared 
        --enable-static 
        )

    xpkg_configure "${xpkg_args[@]}" --disable-shared &&
    xpkg_make_njobs install-lib && 
    xpkg_make_njobs install-lib -C libcharset &&
    xpkg_make_test check 
    return $?
}

