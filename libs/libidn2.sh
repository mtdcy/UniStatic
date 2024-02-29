#!/bin/bash
# Libidn2 is an implementation of the IDNA2008 + TR46 specifications (RFC 5890, RFC 5891, RFC 5892, RFC 5893, TR 46).

upkg_lic='GPL|LGPL'
upkg_ver=2.3.7
upkg_url=https://ftp.gnu.org/gnu/libidn/libidn2-2.3.7.tar.gz
upkg_sha=4c21a791b610b9519b9d0e12b8097bf2f359b12f8dd92647611a929e6bfd7d64
upkg_dep=(libunistring gettext)

upkg_args=(
    --disable-dependency-tracking
    --disable-silent-rules
    --disable-shared
    --enable-static
)

upkg_static() {
    upkg_configure && upkg_make_njobs install
}
