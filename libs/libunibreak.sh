#!/bin/bash
# libass is a portable subtitle renderer for the ASS/SSA (Advanced Substation Alpha/Substation Alpha) subtitle format.

upkg_lic=Zlib
upkg_ver=6.0
upkg_url=https://github.com/adah1972/libunibreak/releases/download/libunibreak_6_0/libunibreak-6.0.tar.gz
upkg_sha=f189daa18ead6312c5db6ed3d0c76799135910ed6c06637c7eea20a7e5e7cc7f
upkg_dep=()

upkg_args=(
    --disable-silent-rules
    --disable-shared
    --enable-static
)

upkg_static() {
    upkg_configure && upkg_make_njobs && upkg_make install 
}
