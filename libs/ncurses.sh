#!/bin/bash
#
# Text-based UI library

upkg_lic='MIT'
upkg_ver=6.4
upkg_url=https://ftp.gnu.org/gnu/ncurses/ncurses-$upkg_ver.tar.gz
upkg_sha=6931283d9ac87c5073f30b6290c4c75f21632bb4fc3603ac8100812bed248159
upkg_dep=()

upkg_args=(
    --disable-option-checking
    --enable-silent-rules
    --disable-dependency-tracking

    --enable-pc-files
    --with-pkg-config-libdir="$PREFIX/lib/pkgconfig"
    --enable-sigwinch
    --enable-symlinks
    --enable-widec
    --enable-overwrite

    --without-debug
    --without-shared
    --without-cxx-shared
    --without-manpages
    --without-ada
    --with-gpm=no
)

upkg_static() {
    # clear installed files
    [ -f config.log ] && [ -f Makefile ] && upkg_uninstall || true

    upkg_configure && 
    upkg_make_njobs &&
    # test
    ./progs/tput -V | grep -F "$upkg_ver" &&
    # check & install
    upkg_install check install &&
    # verify
    upkg_print_linked $PREFIX/bin/tput
}

