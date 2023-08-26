#!/bin/bash
#
# BSD 3-Clause

xpkg_lic="BSD"
xpkg_ver=0.1.5
xpkg_url=https://downloads.sourceforge.net/opencore-amr/opencore-amr-$xpkg_ver.tar.gz
xpkg_sha=2c006cb9d5f651bfb5e60156dbff6af3c9d35c7bbcc9015308c0aff1e14cd341

xpkg_args=(
--disable-debug 
--enable-amrnb-decoder 
--enable-amrnb-encoder
--enable-shared
--enable-static 
)

xpkg_static() {
    xpkg_configure "${xpkg_args[@]}" --disable-shared && xpkg_make_njobs install 
    return $?
}
