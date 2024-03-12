#!/bin/bash
#
# GNU File, Shell, and Text utilities

upkg_lic="GPL-3.0-or-later"
upkg_ver=9.4
upkg_url=https://ftp.gnu.org/gnu/coreutils/coreutils-$upkg_ver.tar.xz
upkg_sha=ea613a4cf44612326e917201bbbcdfbd301de21ffc3b59b6e5c07e040b275e52
upkg_dep=(gmp)

upkg_args=(
    --disable-option-checking
    --enable-silent-rules
    --disable-dependency-tracking
    --without-gmp   # make utils more generic
    --without-selinux
    --without-libiconv-prefix
    --without-libintl-prefix

    # install common used, gnu version of bsd|busybox utils.
    
    --disable-nls
    --disable-doc
    --disable-man
)

upkg_static() {
    # clear installed files
    [ -f config.log ] && [ -f Makefile ] && upkg_uninstall || true

    upkg_configure &&
    upkg_make_njobs &&
    # check & install => there are some FAILs, help-version.sh|uid|zero
    # $MAKE check &&
    upkg_install install-exec
    # verify
    
}
