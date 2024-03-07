#!/bin/bash

upkg_lic="Apache-2.0"
upkg_ver=2.0.2
upkg_url=https://downloads.sourceforge.net/project/opencore-amr/fdk-aac/fdk-aac-$upkg_ver.tar.gz
upkg_sha=c9e8630cf9d433f3cead74906a1520d2223f89bcd3fa9254861017440b8eb22f

upkg_args=(
    --disable-dependency-tracking
    --disable-debug
    --disable-example
    --disable-shared 
    --enable-static
)

upkg_static() {
    rm -fv CMakeLists.txt || true
    upkg_configure && upkg_make_njobs && upkg_make install && upkg_make_test check
}
