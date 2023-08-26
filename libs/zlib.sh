#!/bin/bash

xpkg_lic="zlib"
xpkg_ver=1.2.11
xpkg_url=https://zlib.net/zlib-$xpkg_ver.tar.gz
xpkg_sha=c3e5e9fdd5004dcb542feda5ee4f0ff0744628baf8ed2dd5d66f8ca1197cb1a1

xpkg_static() {
    if xpkg_is_msys; then
        # always static 
        sed -i '/^CC = /d' win32/Makefile.gcc
        sed -i '/^AS = /d' win32/Makefile.gcc
        sed -i '/^LD = /d' win32/Makefile.gcc 
        sed -i '/^CFLAGS = /d' win32/Makefile.gcc 
        sed -i '/^ASFLAGS = /d' win32/Makefile.gcc 
        sed -i '/^LDFLAGS = /d' win32/Makefile.gcc 
        cmd="INCLUDE_PATH=$PREFIX/include LIBRARY_PATH=$PREFIX/lib BINARY_PATH=$PREFIX/bin"
        cmd="$cmd $MAKE -j$XPKG_NJOBS install -f win32/Makefile.gcc"
        info "zlib: $cmd"
        eval $cmd || error "$cmd failed"
    else
        # force configure 
        rm CMakeLists.txt

        xpkg_configure --static && xpkg_make_njobs install 
    fi

    [ $? -eq 0 ] && xpkg_make_test 
    return $?
}
