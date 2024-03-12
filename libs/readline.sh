#!/bin/bash
#
# Library for command-line editing
#
# BE CAREFUL: macOS provide libedit

upkg_lic='GPL-3.0-or-later'
upkg_ver=8.2
upkg_url=https://ftp.gnu.org/gnu/readline/readline-$upkg_ver.tar.gz
upkg_sha=3feb7171f16a84ee82ca18a36d7b9be109a52c04f492a053331d7d1095007c35
upkg_dep=(ncurses)

upkg_args=(
    --disable-option-checking
    --enable-silent-rules
    --disable-dependency-tracking

    # use ncurses instead of termcap
    --with-curses

    --disable-doc
    --disable-man
    --disable-shared
    --enable-static
)

upkg_static() {
    # clear installed files
    [ -f config.log ] && [ -f Makefile ] && upkg_uninstall || true

    upkg_configure && 
    upkg_make_njobs &&
    # check & install
    upkg_install check install-headers install-static install-pc
}

