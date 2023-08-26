#!/bin/bash
# usage: libass.sh <install_prefix>
#
# LICENSE: ISC (BSD 2-Clause)

xpkg_url=https://github.com/libass/libass/releases/download/0.14.0/libass-0.14.0.tar.xz
xpkg_sha=881f2382af48aead75b7a0e02e65d88c5ebd369fe46bc77d9270a94aa8fd38a2

xpkg_static() {
    xpkg_args=(
        --disable-fontconfig #FIXME
        --enable-shared
        --enable-static
    )

    xpkg_configure ${xpkg_args[@]} --disable-shared && 
    xpkg_make_njobs install 
    return $?
}
