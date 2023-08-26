#!/bin/bash
# MIT

xpkg_lic="MIT"
xpkg_ver=2.9.9
xpkg_url=http://xmlsoft.org/sources/libxml2-$xpkg_ver.tar.gz
xpkg_sha=94fb70890143e3c6549f265cee93ec064c80a84c42ad0f23e85ee1fd6540a871

xpkg_static() {
    xpkg_args=(
        --disable-debug 
        --without-python 
        --with-zlib=$PREFIX
        --with-lzma=$PREFIX
        --with-conv=$PREFIX
        --enable-shared 
        --enable-static
        )

    xpkg_configure "${xpkg_args[@]}" --disable-shared &&
    xpkg_make_njobs install && { 
        # fixme: test fails in MSYS2
        xpkg_is_msys || xpkg_make_test check
    }

    return $?
}
