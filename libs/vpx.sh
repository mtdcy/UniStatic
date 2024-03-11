#!/bin/bash

upkg_lic="BSD-3-Clause"
upkg_ver=1.8.0
upkg_url=https://github.com/webmproject/libvpx/archive/v$upkg_ver.tar.gz
upkg_zip=libvpx-$upkg_ver.tar.gz
upkg_sha=86df18c694e1c06cc8f83d2d816e9270747a0ce6abe316e93a4f4095689373f6

upkg_args=(
    --enable-vp8
    --enable-vp9
    --disable-examples
    --disable-unit-tests 
    --enable-vp9-highbitdepth
    #--extra-cflags=\"$CFLAGS\" 
    #--extra-cxxflags=\"$CPPFLAGS\"
    --as=auto
    --disable-shared
    --enable-static
)
    #--disable-libyuv 

upkg_static() {
    upkg_configure && upkg_make_njobs install
}

#if [[ "$OSTYPE" == "darwin"* ]]; then
#    sed -i 's/-Wl,--no-undefined/-Wl,-undefined,error/g' build/$MAKE/Makefile
#    sed -i 's/-Wl,--no-undefined/-Wl,-undefined,error/g' Makefile
#fi
