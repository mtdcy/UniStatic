#!/bin/bash

upkg_lic=""
upkg_ver=2.4.120
upkg_url=https://dri.freedesktop.org/libdrm/libdrm-$upkg_ver.tar.xz
upkg_sha=3bf55363f76c7250946441ab51d3a6cc0ae518055c0ff017324ab76cdefb327a

upkg_static() {
    mkdir -pv build && cd build &&
    meson setup \
            --prefix=$PREFIX         \
            --libdir=lib             \
            --buildtype=release      \
            -Dudev=false             \
            -Dcairo-tests=disabled   \
            -Dvalgrind=disabled      \
            -Ddefault_library=static \
            ..
    ninja &&
    ninja install 
}
