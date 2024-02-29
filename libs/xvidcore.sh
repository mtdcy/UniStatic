#!/bin/bash
# GPL

upkg_lic="GPL"
upkg_ver=1.3.5
upkg_url=https://downloads.xvid.com/downloads/xvidcore-$upkg_ver.tar.bz2
upkg_zip=xvidcore.tar.bz2
upkg_sha=7c20f279f9d8e89042e85465d2bcb1b3130ceb1ecec33d5448c4589d78f010b4

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

    return $?
}
