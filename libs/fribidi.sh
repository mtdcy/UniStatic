#!/bin/bash
# LGPL 2.1 
# for libass

xpkg_lic=LGPL
xpkg_ver=1.0.5
xpkg_url=https://github.com/fribidi/fribidi/releases/download/v$xpkg_ver/fribidi-$xpkg_ver.tar.bz2
xpkg_sha=6a64f2a687f5c4f203a46fa659f43dd43d1f8b845df8d723107e8a7e6158e4ce

xpkg_static() {
    xpkg_args=(
        --disable-debug
        --enable-shared
        --enable-static
        )

    xpkg_configure "${xpkg_args[@]}" --disable-shared && 
    xpkg_make_njobs install && 
    echo "a _lsimple _RteST_o th_oat" > test.input &&
    output=$($PREFIX/bin/fribidi --charset=CapRTL --test test.input)

    echo $output 

    [ "${output#*=> }" = "a simple TSet that" ] 
    return $?
}

