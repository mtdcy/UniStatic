#!/bin/bash
# GPL


xpkg_lic="GPL"
xpkg_ver=1.3.5
xpkg_url=https://downloads.xvid.com/downloads/xvidcore-$xpkg_ver.tar.bz2
xpkg_zip=xvidcore.tar.bz2
xpkg_sha=7c20f279f9d8e89042e85465d2bcb1b3130ceb1ecec33d5448c4589d78f010b4


xpkg_static() {
    cd build/generic 

    xpkg_configure && xpkg_make_njobs all || return $?

    # fix error: symbolic link exists
    unlink $PREFIX/lib/libxvidcore.so 2> /dev/null
    unlink $PREFIX/lib/libxvidcore.so.4 2> /dev/null

    # force removing shared lib 
    xpkg_is_static || {
        xpkg_is_msys && rm -rfv $PREFIX/lib/xvidcore.dll* 
        xpkg_is_macos && rm -rfv $PREFIX/lib/libxvidcore.*.dylib 
        xpkg_is_linux && rm -rfv $PREFIX/lib/libxvidcore.so*
    }

    xpkg_make install 
    return $?
}
