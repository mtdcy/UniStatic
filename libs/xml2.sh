#!/bin/bash
# MIT

upkg_lic="MIT"
upkg_ver=2.9.9
upkg_url=http://xmlsoft.org/sources/libxml2-$upkg_ver.tar.gz
upkg_sha=94fb70890143e3c6549f265cee93ec064c80a84c42ad0f23e85ee1fd6540a871

upkg_static() {
    upkg_args=(
        --disable-debug 
        --without-python 
        --with-zlib=$PREFIX
        --with-lzma=$PREFIX
        --with-conv=$PREFIX
        --enable-shared 
        --enable-static
        )

    upkg_configure "${upkg_args[@]}" --disable-shared &&
    upkg_make_njobs install && { 
        # fixme: test fails in MSYS2
        upkg_msys || upkg_make_test check
    }

    return $?
}
