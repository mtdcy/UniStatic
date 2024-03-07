#!/bin/bash

upkg_lic="LGPL-2.1-or-later"
upkg_ver=0.1.3
upkg_url=https://downloads.sourceforge.net/project/soxr/soxr-$upkg_ver-Source.tar.xz
upkg_sha=b111c15fdc8c029989330ff559184198c161100a59312f5dc19ddeb9b5a15889

upkg_args=(
    -DWITH_OPENMP=OFF
    -DBUILD_SHARED_LIBS=OFF
    -DBUILD_TESTS=OFF
    -DBUILD_EXAMPLES=OFF
    -DWITH_LSR_BINDINGS=OFF
)

upkg_static() {
    # rebuild will fail 
    find . -name CMakeCache.txt -exec rm -fv {} \; || true
    find . -name CMakeFiles exec rm -fv {} \; || true

    upkg_configure && {
        grep "Libs.private" src/soxr.pc || echo "Libs.private: -lm" >> src/soxr.pc
        grep "Libs.private" src/soxr-lsr.pc || echo "Libs.private: -lm" >> src/soxr-lsr.pc
    } && 
    upkg_make_njobs install
}
