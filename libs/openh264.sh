#!/bin/bash
# BSD

xpkg_ver=1.8.0
xpkg_url=https://github.com/cisco/openh264/archive/v$xpkg_ver.tar.gz
xpkg_zip=openh264-$xpkg_ver.tar.gz 
xpkg_sha=08670017fd0bb36594f14197f60bebea27b895511251c7c64df6cd33fc667d34

xpkg_static() {
    # remove default value, using env instead
    sed -i '/^PREFIX=*/d' Makefile 

    xpkg_is_msys && {
        sed -i '/^CC =/d' build/platform-mingw_nt.mk
        sed -i '/^CXX =/d' build/platform-mingw_nt.mk
        sed -i '/^AR =/d' build/platform-mingw_nt.mk
    }

    xpkg_is_static &&
    xpkg_make_njobs install-static ||
    xpkg_make_njobs install-shared

    return $?
}

