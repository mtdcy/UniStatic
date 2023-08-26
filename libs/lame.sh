#!/bin/bash
# License: LGPL

xpkg_lic="LGPL"
xpkg_ver=3.100
xpkg_url=https://sourceforge.net/projects/lame/files/lame/$xpkg_ver/lame-$xpkg_ver.tar.gz
xpkg_sha=ddfe36cab873794038ae2c1210557ad34857a4b6bdc515785d1da9e175b1da1e

xpkg_args=(
    --disable-debug 
    --disable-frontend 
    --enable-nasm
    --enable-shared
    --enable-static
)

xpkg_static() {
    # Fix undefined symbol error _lame_init_old
    # https://sourceforge.net/p/lame/mailman/message/36081038/
    sed -i '/lame_init_old/d' include/libmp3lame.sym

    xpkg_configure "${xpkg_args[@]}" --disable-shared &&
    xpkg_make_njobs install &&
    xpkg_make_test 
    return $?
}
