#!/bin/bash
# libass is a portable subtitle renderer for the ASS/SSA (Advanced Substation Alpha/Substation Alpha) subtitle format.

upkg_lic=FTL
upkg_ver=2.13.2
upkg_url=https://downloads.sourceforge.net/project/freetype/freetype2/2.13.2/freetype-2.13.2.tar.xz
upkg_sha=12991c4e55c506dd7f9b765933e62fd2be2e06d421505d7950a132e4f1bb484d
upkg_dep=(zlib bzip2 brotli)

upkg_args=(
    --enable-freetype-config
    --without-harfbuzz
    --disable-shared
    --enable-static
)

upkg_static() {
    rm CMakeLists.txt # force use configure 
    upkg_configure && upkg_make_njobs && upkg_make install 
}
