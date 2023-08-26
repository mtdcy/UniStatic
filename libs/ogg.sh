#!/bin/bash
# BSD 3-Clause

xpkg_lic="BSD"
xpkg_ver=1.3.3
xpkg_url=https://downloads.xiph.org/releases/ogg/libogg-$xpkg_ver.tar.gz
xpkg_sha=c2e8a485110b97550f453226ec644ebac6cb29d1caef2902c007edab4308d985

xpkg_args=(
    --disable-debug
    --enable-shared
    --enable-static
)

xpkg_static() {
    xpkg_configure "${xpkg_args[@]}" --disable-shared &&
    xpkg_make_njobs install &&
    xpkg_make_test check
}
