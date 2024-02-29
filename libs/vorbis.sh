#!/bin/bash
# BSD 3-Clause

upkg_lic="BSD"
upkg_ver=1.3.6
upkg_url=https://downloads.xiph.org/releases/vorbis/libvorbis-$upkg_ver.tar.xz
upkg_sha=af00bb5a784e7c9e69f56823de4637c350643deedaf333d0fa86ecdba6fcb415


upkg_args=(
    --disable-debug
    --enable-shared 
    --enable-static
)

upkg_static() {
    upkg_configure "${upkg_args[@]}" --disable-shared &&
    upkg_make_njobs install &&
    upkg_make_test check
    return $?
}
