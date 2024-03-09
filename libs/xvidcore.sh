#!/bin/bash
# High-performance, high-quality MPEG-4 video library

upkg_lic="GPL-2.0-or-later"
upkg_ver=1.3.7
upkg_url=https://downloads.xvid.com/downloads/xvidcore-$upkg_ver.tar.bz2
upkg_zip=xvidcore.tar.bz2
upkg_sha=aeeaae952d4db395249839a3bd03841d6844843f5a4f84c271ff88f7aa1acff7

upkg_static() {
    cd build/generic 

    upkg_configure --disable-shared --enable-static &&
    upkg_make_njobs all

    # fix error: symbolic link exists
    unlink $PREFIX/lib/libxvidcore.so 2> /dev/null
    unlink $PREFIX/lib/libxvidcore.so.4 2> /dev/null
    
    upkg_make install 

    # force removing shared lib 
    upkg_msys  && rm -rfv $PREFIX/lib/xvidcore.dll*
    upkg_darwin && rm -rfv $PREFIX/lib/libxvidcore.*.dylib
    upkg_linux && rm -rfv $PREFIX/lib/libxvidcore.so*

    return 0
}
