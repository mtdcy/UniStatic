#!/bin/bash
# BSD 3-Clause

upkg_lic="BSD"
upkg_ver=1.3.3
upkg_url=https://downloads.xiph.org/releases/ogg/libogg-$upkg_ver.tar.gz
upkg_sha=c2e8a485110b97550f453226ec644ebac6cb29d1caef2902c007edab4308d985

upkg_args=(
    --disable-debug
    --enable-shared
    --enable-static
)

upkg_static() {
    upkg_configure "${upkg_args[@]}" --disable-shared &&
    upkg_make_njobs install &&
    upkg_make_test check
}
