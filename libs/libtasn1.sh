#!/bin/bash

upkg_lic='LGPL'
upkg_ver=4.19.0
upkg_url=https://ftp.gnu.org/gnu/libtasn1/libtasn1-$upkg_ver.tar.gz
upkg_sha=1613f0ac1cf484d6ec0ce3b8c06d56263cc7242f1c23b30d82d23de345a63f7a

upkg_args=(
    --disable-dependency-tracking
    --disable-silent-rules
    --disable-shared
    --enable-static
)

upkg_static() {
    upkg_configure && upkg_make_njobs install
}
