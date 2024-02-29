#!/bin/bash
# LGPL 2.1 
# for libass

upkg_lic=LGPL
upkg_ver=1.0.5
upkg_url=https://github.com/fribidi/fribidi/releases/download/v$upkg_ver/fribidi-$upkg_ver.tar.bz2
upkg_sha=6a64f2a687f5c4f203a46fa659f43dd43d1f8b845df8d723107e8a7e6158e4ce

upkg_static() {
    upkg_args=(
        --disable-debug
        --enable-shared
        --enable-static
        )

    upkg_configure "${upkg_args[@]}" --disable-shared && 
    upkg_make_njobs install && 
    echo "a _lsimple _RteST_o th_oat" > test.input &&
    output=$($PREFIX/bin/fribidi --charset=CapRTL --test test.input)

    echo $output 

    [ "${output#*=> }" = "a simple TSet that" ] 
    return $?
}

