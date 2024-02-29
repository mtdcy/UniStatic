#!/bin/bash
# BSD 3-Clause

upkg_ver=1.8.0
upkg_url=https://github.com/webmproject/libvpx/archive/v$upkg_ver.tar.gz
upkg_zip=libvpx-$upkg_ver.tar.gz
upkg_sha=86df18c694e1c06cc8f83d2d816e9270747a0ce6abe316e93a4f4095689373f6

upkg_static() {
    upkg_args=(
        --enable-vp8
        --enable-vp9
        --disable-examples
        --disable-multithread 
        --extra-cflags=\"$CFLAGS\" 
        --extra-cxxflags=\"$CPPFLAGS\"
        --as=yasm          # libvpx prefer yasm
        #--disable-libyuv 
    )

    upkg_is_static && upkg_args+=(--enable-static --disable-shared) || {
        if upkg_darwin; then
            # build shared failed with clang
            upkg_args+=(--disable-shared --enable-static)
        elif upkg_msys; then
            # shared not supported on win32
            upkg_args+=(--disable-shared --enable-static)
            # https://stackoverflow.com/questions/43152633/invalid-register-for-seh-savexmm-in-cygwin
            upkg_args+=(
            --extra-cflags=-fno-asynchronous-unwind-tables
            --disable-unit-tests # FIXME: failed to build gtest
            )
        else
            upkg_args+=(--enable-shared --enable-pic --disable-static)
        fi
    }

    upkg_configure "${upkg_args[@]}" &&
    upkg_make_njobs install &&
    upkg_make_test check
    return $?
}

#if [[ "$OSTYPE" == "darwin"* ]]; then
#    sed -i 's/-Wl,--no-undefined/-Wl,-undefined,error/g' build/$MAKE/Makefile
#    sed -i 's/-Wl,--no-undefined/-Wl,-undefined,error/g' Makefile
#fi
