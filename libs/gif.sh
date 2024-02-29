#!/bin/bash
#

upkg_ver=5.1.4
upkg_url=https://downloads.sourceforge.net/project/giflib/giflib-$upkg_ver.tar.bz2
upkg_sha=df27ec3ff24671f80b29e6ab1c4971059c14ac3db95406884fc26574631ba8d5

upkg_args=(
    --disable-debug
    --enable-shared 
    --enable-static
)

upkg_static() {
    upkg_configure "${upkg_args[@]}" --disable-shared &&
    upkg_make_njobs install &&
    upkg_make_test -C tests
    return $?
}
