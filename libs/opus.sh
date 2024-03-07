#!/bin/bash
# Audio Codec

upkg_lic="BSD-3-Clause"
upkg_ver=1.5.1
upkg_url=https://downloads.xiph.org/releases/opus/opus-$upkg_ver.tar.gz
upkg_sha=b84610959b8d417b611aa12a22565e0a3732097c6389d19098d844543e340f85
upkg_dep=()

upkg_args=(
    --disable-debug 
    --disable-extra-programs
    --disable-shared
    --enable-static
)

upkg_static() {
    # force configure instead of cmake 
    rm CMakeLists.txt

    upkg_configure && upkg_make_njobs install && upkg_make_test check
}
