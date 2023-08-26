#!/bin/bash

xpkg_lic=""
xpkg_ver=5.2.4
xpkg_url=https://tukaani.org/xz/xz-$xpkg_ver.tar.bz2
xpkg_sha=3313fd2a95f43d88e44264e6b015e7d03053e681860b0d5d3f9baca79c57b7bf

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
