#!/bin/bash
#

xpkg_ver=2.3.1
xpkg_url=https://github.com/uclouvain/openjpeg/archive/v$xpkg_ver.tar.gz
xpkg_zip=openjpeg-$xpkg_ver.tar.gz
xpkg_sha=63f5a4713ecafc86de51bfad89cc07bb788e9bba24ebbf0c4ca637621aadb6a9

xpkg_static() {
    xpkg_args=(
        -DXPKG_SHARED_LIBS=ON 
        -DBUILD_STATIC_LIBS=ON
        # no applications
        -DBUILD_CODEC=OFF
    )

    xpkg_configure "${xpkg_args[@]}" -DXPKG_SHARED_LIBS=OFF &&
    xpkg_make_njobs install 
    return $?
}
