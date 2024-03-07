#!/bin/bash
# Library and utilities for processing GIFs

upkg_lic=""
upkg_ver=5.2.1
upkg_url=https://downloads.sourceforge.net/project/giflib/giflib-$upkg_ver.tar.gz
upkg_sha=31da5562f44c5f15d63340a09a4fd62b48c45620cd302f77a6d9acf0077879bd
upkg_dep=()

upkg_args=(
    --disable-debug
    --disable-shared 
    --enable-static
)

upkg_static() {
    upkg_configure && upkg_make_njobs install && upkg_make_test -C tests
}
