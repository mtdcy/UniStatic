#!/bin/bash

upkg_lic='LGPL|GPL'
upkg_ver=6.3.0
upkg_url=https://ftp.gnu.org/gnu/gmp/gmp-6.3.0.tar.xz
upkg_sha=a3c2b80201b89e68616f4ad30bc66aee4927c3ce50e33929ca819d5c43538898
upkg_dep=()

upkg_args=(
    --enable-cxx 
    --with-pic
    --disable-shared
    --enable-static
)

upkg_static() {
    upkg_configure && upkg_make_njobs && upkg_make check install
}
