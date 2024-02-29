#!/bin/bash
# This library provides functions for manipulating Unicode strings and for manipulating C strings according to the Unicode standard.
#
upkg_lic='LGPL|GPL'
upkg_ver=1.1
upkg_url=https://ftp.gnu.org/gnu/libunistring/libunistring-1.1.tar.gz
upkg_sha=a2252beeec830ac444b9f68d6b38ad883db19919db35b52222cf827c385bdb6a
upkg_dep=()

upkg_args=(
    --disable-dependency-tracking
    --disable-silent-rules
    --disable-shared
    --enable-static
)

upkg_static() {
    upkg_configure && upkg_make_njobs install
}
