#!/bin/bash
# 
# GNU gettext utilities are a set of tools that provides a framework to help other GNU packages produce multi-lingual messages.

upkg_lic='GPL'
upkg_ver=0.22.5
upkg_url=https://ftp.gnu.org/gnu/gettext/gettext-0.22.5.tar.gz
upkg_sha=ec1705b1e969b83a9f073144ec806151db88127f5e40fe5a94cb6c8fa48996a0
upkg_dep=(libunistring xml2)

upkg_args=(
    --disable-dependency-tracking
    --disable-silent-rules
    --with-included-glib
    --with-included-libcroco
    --without-included-libunistring
    --without-included-libxml
    # Don't use VCS systems
    --without-git
    --without-cvs
    --without-xz
    # static only
    --disable-shared
    --enable-static
)

upkg_static() {
    # install doesn't support multiple make jobs
    upkg_configure && upkg_make_njobs && upkg_make install
}
