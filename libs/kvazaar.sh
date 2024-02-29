#!/bin/bash
# LGPL

upkg_ver=1.2.0
upkg_url=https://github.com/ultravideo/kvazaar/releases/download/v1.2.0/kvazaar-$upkg_ver.tar.xz
upkg_sha=9bc9ba4d825b497705bd6d84817933efbee43cbad0ffaac17d4b464e11e73a37

upkg_static() {
    upkg_args=(
        --disable-debug
        --enable-shared
        --enable-static
        )

    upkg_configure "${upkg_args[@]}" --disable-shared &&
    upkg_make_njobs install 
    return $?
}
