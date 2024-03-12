#!/bin/bash
#
# GNU implementation of the famous stream editor

upkg_lic='GPL-3.0-or-later'
upkg_ver=4.9
upkg_url=https://ftp.gnu.org/gnu/sed/sed-$upkg_ver.tar.xz
upkg_sha=6e226b732e1cd739464ad6862bd1a1aba42d7982922da7a53519631d24975181
upkg_dep=()

upkg_args=(
    --disable-option-checking
    --enable-silent-rules
    --disable-dependency-tracking

    --without-selinux
    --without-libiconv-prefix
    --without-libintl-prefix

    --disable-nls
    --disable-doc
    --disable-man

    --program-prefix=g
)

upkg_static() {
    # clear installed files
    [ -f config.log ] && [ -f Makefile ] && upkg_uninstall || true

    upkg_configure && 
    upkg_make_njobs &&
    # test
    ./sed/sed --version | grep -F "$upkg_ver" &&
    # check & install
    upkg_install check install-exec &&
    # provide default 'sed'
    ln -sfv gsed $PREFIX/bin/sed &&
    # verify
    upkg_print_linked $PREFIX/bin/gsed
}

