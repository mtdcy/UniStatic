#!/bin/bash
# License: LGPL

upkg_lic="LGPL"
upkg_ver=3.100
upkg_url=https://sourceforge.net/projects/lame/files/lame/$upkg_ver/lame-$upkg_ver.tar.gz
upkg_sha=ddfe36cab873794038ae2c1210557ad34857a4b6bdc515785d1da9e175b1da1e

upkg_args=(
    --disable-debug 
    --disable-frontend 
    --enable-nasm
    --enable-shared
    --enable-static
)

upkg_static() {
    # Fix undefined symbol error _lame_init_old
    # https://sourceforge.net/p/lame/mailman/message/36081038/
    sed -i '/lame_init_old/d' include/libmp3lame.sym

    upkg_configure "${upkg_args[@]}" --disable-shared &&
    upkg_make_njobs install &&
    upkg_make_test 
    return $?
}
