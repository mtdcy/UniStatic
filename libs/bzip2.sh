#!/bin/bash

xpkg_lic=""
xpkg_ver=1.0.6
xpkg_url=https://ftp.osuosl.org/pub/clfs/conglomeration/bzip2/bzip2-$xpkg_ver.tar.gz
xpkg_sha=a2848f34fcd5d6cf47def00461fcb528a0484d8edef8208d6d2e2909dc61d9cd

xpkg_static() {
    sed -i '/CC=gcc/d' Makefile
    sed -i '/AR=ar/d' Makefile
    sed -i '/RANLIB=ranlib/d' Makefile
    sed -i '/LDFLAGS=/d' Makefile
    sed -i 's/CFLAGS=/CFLAGS+=/g' Makefile
    xpkg_make install PREFIX=$PREFIX && xpkg_make_test 
    return $?
}
