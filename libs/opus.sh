#!/bin/bash
# BSD 3-Clause

xpkg_lic="BSD"
xpkg_ver=1.3.1
xpkg_url=https://archive.mozilla.org/pub/opus/opus-$xpkg_ver.tar.gz
xpkg_sha=65b58e1e25b2a114157014736a3d9dfeaad8d41be1c8179866f144a2fb44ff9d


xpkg_args=(
    --disable-debug 
    --disable-extra-programs
    --enable-static
)

xpkg_static() {
    # force configure instead of cmake 
    rm CMakeLists.txt

    xpkg_configure "${xpkg_args[@]}" &&
    xpkg_make_njobs install &&
    xpkg_make_test check
    return $?
}
