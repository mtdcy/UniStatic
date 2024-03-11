#!/bin/bash
# 

upkg_lic="GPL-3.0-or-later|LGPL-2.0-or-later"
upkg_ver=1.17
upkg_url=https://ftp.gnu.org/pub/gnu/libiconv/libiconv-$upkg_ver.tar.gz
upkg_sha=8f74213b56238c85a50a5329f77e06198771e70dd9a739779f4c02f65d971313

upkg_args=(
    --disable-option-checking
    --disable-dependency-tracking
    --enable-extra-encodings 
    --disable-debug 
    --disable-shared 
    --enable-static 
    )

upkg_static() {
    upkg_configure && upkg_make_njobs install-lib && upkg_make_njobs install-lib -C libcharset && upkg_make_test check 
}

