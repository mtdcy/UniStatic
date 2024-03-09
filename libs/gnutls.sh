#!/bin/bash

upkg_lic='LGPL|GPL'
upkg_ver=3.8.3
upkg_url=https://www.gnupg.org/ftp/gcrypt/gnutls/v3.8/gnutls-3.8.3.tar.xz
upkg_sha=f74fc5954b27d4ec6dfbb11dea987888b5b124289a3703afcada0ee520f4173e
upkg_dep=(brotli gmp libidn2 libtasn1 nettle libunistring gettext)

upkg_args=(
    --disable-dependency-tracking
    --disable-silent-rules
    --without-p11-kit
    --disable-heartbeat-support
    --disable-shared
    --enable-static
    --disable-tests
)

upkg_static() {
    upkg_configure && upkg_make_njobs && upkg_make install
}
