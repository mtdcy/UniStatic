#!/bin/bash
# BSD 3-Clause

upkg_lic="BSD"
upkg_ver=2.0.0
upkg_url=https://downloads.sourceforge.net/project/opencore-amr/fdk-aac/fdk-aac-$upkg_ver.tar.gz
upkg_sha=f7d6e60f978ff1db952f7d5c3e96751816f5aef238ecf1d876972697b85fd96c

upkg_args=(
    --disable-debug
    --enable-shared 
    --enable-static
)

upkg_static() {
    upkg_configure "${upkg_args[@]}" --disable-shared &&
    upkg_make_njobs install &&
    upkg_make_test check
    return $?
}
