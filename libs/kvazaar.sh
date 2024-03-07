#!/bin/bash
# Ultravideo HEVC encoder

upkg_lic="BSD-3-Clause"
upkg_ver=2.3.0
upkg_url=https://github.com/ultravideo/kvazaar/releases/download/v$upkg_ver/kvazaar-$upkg_ver.tar.gz
upkg_sha=75fd2b50be3c57b898f0a0e3549be6017d39cf3dda11c80853ac9bf6aadb5958

upkg_args=(
    --disable-option-checking
    --enable-silent-rules
    --disable-dependency-tracking
    --disable-debug
    --disable-shared
    --enable-static
    )

upkg_static() {
    upkg_configure && upkg_make_njobs &&
    # fix kvazaar.pc
    sed -e "s@^prefix=.*@prefix=$PREFIX@" \
        -e "s@^Version:.*@Version: $upkg_ver@" \
        -i src/kvazaar.pc &&
    upkg_make install
}
