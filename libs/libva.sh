#!/bin/bash

upkg_lic=""
upkg_ver=2.20.0
upkg_url=https://github.com/intel/libva/releases/download/$upkg_ver/libva-$upkg_ver.tar.bz2
upkg_sha=f72bdb4f48dfe71ad01f1cbefe069672a2c949a6abd51cf3c4d4784210badc49

upkg_static() {
    ./configure             \
        --enable-static     \
        --disable-shared    \
        --prefix=$PREFIX    \
        --enable-drm        \
        --disable-x11       \
        --disable-glx       \
        --disable-wayland &&
    make -j$UPKG_NJOBS &&
    make install
}
