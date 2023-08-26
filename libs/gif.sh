#!/bin/bash
#

xpkg_ver=5.1.4
xpkg_url=https://downloads.sourceforge.net/project/giflib/giflib-$xpkg_ver.tar.bz2
xpkg_sha=df27ec3ff24671f80b29e6ab1c4971059c14ac3db95406884fc26574631ba8d5

xpkg_args=(
    --disable-debug
    --enable-shared 
    --enable-static
)

xpkg_static() {
    xpkg_configure "${xpkg_args[@]}" --disable-shared &&
    xpkg_make_njobs install &&
    xpkg_make_test -C tests
    return $?
}
