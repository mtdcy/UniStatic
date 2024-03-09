#!/bin/bash
# Extremely Fast Compression algorithm

upkg_lic="BSD-2-Clause"
upkg_ver=1.9.4
upkg_url=https://github.com/lz4/lz4/releases/download/v$upkg_ver/lz4-$upkg_ver.tar.gz
upkg_sha=0b0e3aa07c8c063ddf40b082bdf7e37a1562bda40a0ff5272957f3e987e0e54b
upkg_dep=()
# lz4

upkg_args=(
)

upkg_static() {
    sed -e 's/^BUILD_SHARED.*:=.*$/BUILD_SHARED:=no/' -i lib/Makefile &&
    upkg_make_njobs && upkg_make install PREFIX="$PREFIX"
}
