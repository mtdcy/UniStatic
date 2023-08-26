#!/bin/bash
# BSD 3-Clause

xpkg_ver=1.8.0
xpkg_url=https://github.com/webmproject/libvpx/archive/v$xpkg_ver.tar.gz
xpkg_zip=libvpx-$xpkg_ver.tar.gz
xpkg_sha=86df18c694e1c06cc8f83d2d816e9270747a0ce6abe316e93a4f4095689373f6

xpkg_static() {
    xpkg_args=(
        --enable-vp8
        --enable-vp9
        --disable-examples
        --disable-multithread 
        --extra-cflags=\"$CFLAGS\" 
        --extra-cxxflags=\"$CPPFLAGS\"
        --as=yasm          # libvpx prefer yasm
        #--disable-libyuv 
    )

    xpkg_is_static && xpkg_args+=(--enable-static --disable-shared) || {
        if xpkg_is_macos; then
            # build shared failed with clang
            xpkg_args+=(--disable-shared --enable-static)
        elif xpkg_is_msys; then
            # shared not supported on win32
            xpkg_args+=(--disable-shared --enable-static)
            # https://stackoverflow.com/questions/43152633/invalid-register-for-seh-savexmm-in-cygwin
            xpkg_args+=(
            --extra-cflags=-fno-asynchronous-unwind-tables
            --disable-unit-tests # FIXME: failed to build gtest
            )
        else
            xpkg_args+=(--enable-shared --enable-pic --disable-static)
        fi
    }

    xpkg_configure "${xpkg_args[@]}" &&
    xpkg_make_njobs install &&
    xpkg_make_test check
    return $?
}

#if [[ "$OSTYPE" == "darwin"* ]]; then
#    sed -i 's/-Wl,--no-undefined/-Wl,-undefined,error/g' build/$MAKE/Makefile
#    sed -i 's/-Wl,--no-undefined/-Wl,-undefined,error/g' Makefile
#fi
