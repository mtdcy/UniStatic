#!/bin/bash
# BSD 3-Clause

upkg_lic="BSD"
upkg_ver=1.3.1
upkg_url=https://archive.mozilla.org/pub/opus/opus-$upkg_ver.tar.gz
upkg_sha=65b58e1e25b2a114157014736a3d9dfeaad8d41be1c8179866f144a2fb44ff9d


upkg_args=(
    --disable-debug 
    --disable-extra-programs
    --enable-static
)

upkg_static() {
    # force configure instead of cmake 
    rm CMakeLists.txt

    upkg_configure "${upkg_args[@]}" --disable-shared &&
    upkg_make_njobs install &&
    upkg_make_test check
    return $?
}
