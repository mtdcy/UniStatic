#!/bin/bash
# libass is a portable subtitle renderer for the ASS/SSA (Advanced Substation Alpha/Substation Alpha) subtitle format.

upkg_lic=ISC
upkg_ver=0.17.1
upkg_url=https://github.com/libass/libass/releases/download/0.17.1/libass-0.17.1.tar.xz
upkg_sha=f0da0bbfba476c16ae3e1cfd862256d30915911f7abaa1b16ce62ee653192784
upkg_dep=(fribidi harfbuzz freetype libunibreak)

upkg_args=(
    --enable-silent-rules
    --disable-option-checking
    --disable-dependency-tracking
    --disable-require-system-font-provider
    --disable-shared
    --enable-static
)

upkg_static() {
    # use coretext on mac
    upkg_darwin && extra_args=(--disable-fontconfig)

    upkg_configure "${extra_args[@]}" && 
    upkg_make_njobs &&
    upkg_make install 
}
