#!/bin/bash
#
# BSD 3-Clause

upkg_lic="BSD"
upkg_ver=0.1.5
upkg_url=https://downloads.sourceforge.net/opencore-amr/opencore-amr-$upkg_ver.tar.gz
upkg_sha=2c006cb9d5f651bfb5e60156dbff6af3c9d35c7bbcc9015308c0aff1e14cd341

upkg_args=(
    --disable-debug 
    --enable-amrnb-decoder 
    --enable-amrnb-encoder
    --disable-shared
    --enable-static 
)

upkg_static() {
    upkg_configure && upkg_make_njobs && upkg_make install 
}
