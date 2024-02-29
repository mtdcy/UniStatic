#!/bin/bash

upkg_lic=""
upkg_ver=5.2.4
upkg_url=https://sourceforge.net/projects/lzmautils/files/xz-5.2.4.tar.bz2
upkg_sha=3313fd2a95f43d88e44264e6b015e7d03053e681860b0d5d3f9baca79c57b7bf

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
