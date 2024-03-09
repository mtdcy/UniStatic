#!/bin/bash
# Generic-purpose lossless compression algorithm by Google

upkg_lic="MIT"
upkg_ver=1.1.0
upkg_url="https://github.com/google/brotli/archive/refs/tags/v$upkg_ver.tar.gz"
upkg_zip=brotli-$upkg_ver.tar.gz
upkg_sha=e720a6ca29428b803f4ad165371771f5398faba397edf6778837a18599ea13ff
upkg_dep=()

upkg_args=(
    -DBUILD_SHARED_LIBS=OFF
)

upkg_static() {
    upkg_configure && upkg_make_njobs V=1 && upkg_make install
}
