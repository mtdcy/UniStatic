#!/bin/bash
# LGPL

xpkg_ver=1.2.0
xpkg_url=https://github.com/ultravideo/kvazaar/releases/download/v1.2.0/kvazaar-$xpkg_ver.tar.xz
xpkg_sha=9bc9ba4d825b497705bd6d84817933efbee43cbad0ffaac17d4b464e11e73a37

xpkg_static() {
    xpkg_args=(
        --disable-debug
        --enable-shared
        --enable-static
        )

    xpkg_configure "${xpkg_args[@]}" &&
    xpkg_make_njobs install 
    return $?
}
