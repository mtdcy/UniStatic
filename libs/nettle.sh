#!/bin/bash

upkg_lic='LGPL|GPL'
upkg_ver=3.9.1
upkg_url=https://ftp.gnu.org/gnu/nettle/nettle-3.9.1.tar.gz
upkg_sha=ccfeff981b0ca71bbd6fbcb054f407c60ffb644389a5be80d6716d5b550c6ce3
upkg_dep=(gmp)

upkg_args=(
    --libdir=$PREFIX/lib    # default install to lib64
    --disable-shared
    --enable-static
)

upkg_static() {
    upkg_configure && upkg_make_njobs install
}

