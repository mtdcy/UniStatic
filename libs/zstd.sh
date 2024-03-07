#!/bin/bash
# Zstandard is a real-time compression algorithm

upkg_lic="BSD-3-Clause"
upkg_ver=1.5.5
upkg_url=https://github.com/facebook/zstd/releases/download/v$upkg_ver/zstd-$upkg_ver.tar.gz
upkg_sha=9c4396cc829cfae319a6e2615202e82aad41372073482fce286fac78646d3ee4
upkg_dep=(zlib lzma lz4)

upkg_args=(
    -DZSTD_BUILD_CONTRIB=ON
    -DZSTD_LEGACY_SUPPORT=ON
    -DZSTD_ZLIB_SUPPORT=ON
    -DZSTD_LZMA_SUPPORT=ON
    -DZSTD_LZ4_SUPPORT=ON
    -DCMAKE_CXX_STANDARD=11
    -DZSTD_BUILD_SHARED=OFF
    -DZSTD_BUILD_STATIC=ON
    -DZSTD_PROGRAMS_LINK_SHARED=OFF
)

upkg_static() {
    cd build/cmake
    upkg_configure . && upkg_make_njobs install

    # ZSTD_BUILD_SHARED=OFF not working?
    rm -fv "$PREFIX/lib/libzstd.so"* || true
}

