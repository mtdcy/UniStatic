#!/bin/bash
# Just-In-Time Compiler (JIT) for the Lua programming language

upkg_lic="MIT"
upkg_ver=2.1
upkg_url=https://github.com/LuaJIT/LuaJIT/archive/c525bcb9024510cad9e170e12b6209aedb330f83.tar.gz
upkg_zip=LuaJIT.$upkg_ver.tar.gz
upkg_sha=eb20affc70a9e97a8a0e1e0b10456f220fca7637a198e4a937b5fc827dd1ef95
upkg_dep=()

upkg_args=(
)

upkg_static() {
    sed -e "s%/usr/local%$PREFIX%" \
        -i Makefile &&

    sed -e "/^CC=/d" \
        -e 's/^BUILDMODE=.*$/BUILDMODE=static/' \
        -i src/Makefile &&

    upkg_make_njobs && 
    rm -fv src/*.so && # no shared lib
    upkg_make install
}
