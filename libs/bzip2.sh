#!/bin/bash

upkg_lic=""
upkg_ver=1.0.6
upkg_url=https://ftp.osuosl.org/pub/clfs/conglomeration/bzip2/bzip2-$upkg_ver.tar.gz
upkg_sha=a2848f34fcd5d6cf47def00461fcb528a0484d8edef8208d6d2e2909dc61d9cd

upkg_static() {
    sed -i '/CC=gcc/d' Makefile
    sed -i '/AR=ar/d' Makefile
    sed -i '/RANLIB=ranlib/d' Makefile
    sed -i '/LDFLAGS=/d' Makefile
    sed -i 's/CFLAGS=/CFLAGS+=/g' Makefile
    
    upkg_make install PREFIX=$PREFIX && upkg_make_test 

    # fix symlink
    cd "$PREFIX/bin"       &&
    ln -sfv bzdiff bzcmp   &&
    ln -sfv bzgrep bzegrep &&
    ln -sfv bzgrep bzfgrep &&
    ln -sfv bzmore bzless  &&
    cd -
}
