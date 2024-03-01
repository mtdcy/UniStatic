#!/bin/bash
# Scaling, colorspace conversion, and dithering library

upkg_lic="WTFPL"
upkg_ver=3.0.5
upkg_url=https://github.com/sekrit-twc/zimg/archive/refs/tags/release-$upkg_ver.tar.gz
upkg_sha=a9a0226bf85e0d83c41a8ebe4e3e690e1348682f6a2a7838f1b8cbff1b799bcf
upkg_zip=zimg-release-$upkg_ver.tar.gz
upkg_dep=()

upkg_args=(
    --disable-debug
    --disable-shared 
    --enable-static
)

upkg_static() {
    ./autogen.sh &&                             \
    upkg_configure &&                           \
    upkg_make_njobs || return $?

    upkg_linux &&                               \
    sed -i 's/^Libs.private:.*$/& -lm/' zimg.pc

    upkg_make install
}
