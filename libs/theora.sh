#!/bin/bash


upkg_lic="BSD 3-Clause"
upkg_ver=1.1.1
upkg_url=https://downloads.xiph.org/releases/theora/libtheora-$upkg_ver.tar.bz2
upkg_sha=b6ae1ee2fa3d42ac489287d3ec34c5885730b1296f0801ae577a35193d3affbc
upkg_dep=(ogg vorbis)

upkg_args=(
    --disable-examples 
    --disable-oggtest 
    --disable-vorbistest 
    --with-ogg=$PREFIX
    --with-vorbis=$PREFIX
    --disable-shared
    --enable-static
    )

upkg_static() {
    upkg_configure && upkg_make_njobs install && upkg_make_test 
}
