#!/bin/bash
# BSD 3-Clause

xpkg_lic="BSD"
xpkg_ver=2.0.0
xpkg_url=https://downloads.sourceforge.net/project/opencore-amr/fdk-aac/fdk-aac-$xpkg_ver.tar.gz
xpkg_sha=f7d6e60f978ff1db952f7d5c3e96751816f5aef238ecf1d876972697b85fd96c

xpkg_args=(
    --disable-debug
    --enable-shared 
    --enable-static
)

xpkg_static() {
    xpkg_configure "${xpkg_args[@]}" --disable-shared &&
    xpkg_make_njobs install &&
    xpkg_make_test check
    return $?
}
