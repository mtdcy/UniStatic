#!/bin/bash
# BSD

upkg_ver=1.8.0
upkg_url=https://github.com/cisco/openh264/archive/v$upkg_ver.tar.gz
upkg_zip=openh264-$upkg_ver.tar.gz 
upkg_sha=08670017fd0bb36594f14197f60bebea27b895511251c7c64df6cd33fc667d34

upkg_static() {
    # remove default value, using env instead
    sed -i '/^PREFIX=*/d' Makefile 

    upkg_msys && {
        sed -i '/^CC =/d' build/platform-mingw_nt.mk
        sed -i '/^CXX =/d' build/platform-mingw_nt.mk
        sed -i '/^AR =/d' build/platform-mingw_nt.mk
    }

    upkg_make_njobs install-static
}

