#!/bin/bash
# 

upkg_lic="LGPL"
upkg_ver=1.15
upkg_url=https://ftp.gnu.org/pub/gnu/libiconv/libiconv-$upkg_ver.tar.gz
upkg_sha=ccf536620a45458d26ba83887a983b96827001e92a13847b45e4925cc8913178

upkg_static() {
    upkg_args=(
        --disable-debug 
        --enable-extra-encodings 
        --enable-shared 
        --enable-static 
        )

    upkg_configure "${upkg_args[@]}" --disable-shared &&
    upkg_make_njobs install-lib && 
    upkg_make_njobs install-lib -C libcharset &&
    upkg_make_test check 
    return $?
}

