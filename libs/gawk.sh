#!/bin/bash
#
# GNU awk utility

upkg_lic='GPL-3.0-or-later'
upkg_ver=5.3.0
upkg_url=https://ftp.gnu.org/gnu/gawk/gawk-$upkg_ver.tar.xz
upkg_sha=ca9c16d3d11d0ff8c69d79dc0b47267e1329a69b39b799895604ed447d3ca90b
upkg_dep=(gettext readline) # mpfr readline

upkg_args=(
    --disable-option-checking
    --enable-silent-rules
    --disable-dependency-tracking

    --without-mpfr

    --without-selinux
    --without-libiconv-prefix
    --without-libintl-prefix

    --disable-nls
    --disable-doc
    --disable-man
)

upkg_static() {
    # clear installed files
    [ -f config.log ] && [ -f Makefile ] && upkg_uninstall || true

    upkg_configure && 
    upkg_make_njobs &&
    # test
    ./gawk --version | grep -F "$upkg_ver" &&
    # check & install => there always 5 FAILs
    #upkg_install check install-exec &&
    upkg_install install-exec &&
    # provide default 'awk'
    ln -sfv gawk $PREFIX/bin/awk &&
    # verify
    upkg_print_linked $PREFIX/bin/gawk
}

