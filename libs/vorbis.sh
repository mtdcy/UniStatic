#!/bin/bash
# BSD 3-Clause

xpkg_lic="BSD"
xpkg_ver=1.3.6
xpkg_url=https://downloads.xiph.org/releases/vorbis/libvorbis-$xpkg_ver.tar.xz
xpkg_sha=af00bb5a784e7c9e69f56823de4637c350643deedaf333d0fa86ecdba6fcb415


xpkg_args=(
    --disable-debug
    --enable-shared 
    --enable-static
)

xpkg_static() {
    xpkg_configure "${xpkg_args[@]}" --disable-shared &&
    xpkg_make_njobs install &&
    xpkg_make_test check
    return $?
}
