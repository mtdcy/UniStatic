#!/bin/bash
# A command-line system information tool written in bash 3.2+

upkg_lic="MIT"
upkg_ver=7.1.0
upkg_url=https://github.com/dylanaraps/neofetch/archive/refs/tags/$upkg_ver.tar.gz
upkg_zip=neofetch-$upkg_ver.tar.gz
upkg_sha=58a95e6b714e41efc804eca389a223309169b2def35e57fa934482a6b47c27e7

upkg_static() {
    upkg_make install
}
