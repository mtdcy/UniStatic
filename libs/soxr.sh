#!/bin/bash

xpkg_lic="LGPL"
xpkg_ver=0.1.3
xpkg_url=https://downloads.sourceforge.net/project/soxr/soxr-$xpkg_ver-Source.tar.xz
xpkg_sha=b111c15fdc8c029989330ff559184198c161100a59312f5dc19ddeb9b5a15889

xpkg_args=(
    -DWITH_OPENMP=OFF
    -DXPKG_SHARED_LIBS=ON
)

xpkg_static() {
    xpkg_configure "${xpkg_args[@]}" -DXPKG_SHARED_LIBS=OFF &&
    xpkg_make_njobs install && 
    xpkg_make_test 
    return $?
}
