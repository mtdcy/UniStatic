#!/bin/bash

upkg_lic="LGPL"
upkg_ver=0.1.3
upkg_url=https://downloads.sourceforge.net/project/soxr/soxr-$upkg_ver-Source.tar.xz
upkg_sha=b111c15fdc8c029989330ff559184198c161100a59312f5dc19ddeb9b5a15889

upkg_args=(
    -DWITH_OPENMP=OFF
    -DBUILD_SHARED_LIBS=ON
)

upkg_static() {
    upkg_configure "${upkg_args[@]}" -DBUILD_SHARED_LIBS=OFF && {
        grep "Libs.private" src/soxr.pc || echo "Libs.private: -lm" >> src/soxr.pc
        grep "Libs.private" src/soxr-lsr.pc || echo "Libs.private: -lm" >> src/soxr-lsr.pc
    } && 
    upkg_make_njobs install &&
    upkg_make_test 
    return $?
}
