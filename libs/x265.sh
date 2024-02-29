#!/bin/bash
# GPL

upkg_lic="GPL"
upkg_ver=3.0
upkg_url=http://ftp.videolan.org/pub/videolan/x265/x265_$upkg_ver.tar.gz
upkg_sha=c5b9fc260cabbc4a81561a448f4ce9cad7218272b4011feabc3a6b751b2f0662


upkg_static() {
    upkg_args=(
        -DEXTRA_LIB=\"x265_main12.a\;x265_main10.a\"
        -DEXTRA_LINK_FLAGS=-L.
        -DLINKED_12BIT=ON
        -DLINKED_10BIT=ON
        -DENABLE_SHARED=OFF
        )

    upkg_args_high=(
        -DHIGH_BIT_DEPTH=ON 
        -DEXPORT_C_API=OFF 
        -DENABLE_CLI=OFF 
        -DENABLE_SHARED=OFF
        )

    # build high bits always as static
    mkdir -p {8bit,10bit,12bit}
    # 12 bit
    cd 12bit 
    upkg_configure "${upkg_args_high[@]}" -DMAIN12=ON ../source && 
    upkg_make &&
    mv libx265.a ../8bit/libx265_main12.a || return $?
    cd -

    # 10bit
    cd 10bit 
    upkg_configure "${upkg_args_high[@]}" -DENABLE_HDR10_PLUS=ON ../source && 
    upkg_make &&
    mv libx265.a ../8bit/libx265_main10.a || return $?
    cd -

    # it seems x265 has problem with njobs
    # 8bit
    cd 8bit
    upkg_configure "${upkg_args[@]}" ../source &&
    upkg_make &&
    mv libx265.a libx265_main.a || return $?

    upkg_darwin && 
    libtool -static -o libx265.a libx265_main.a libx265_main10.a libx265_main12.a || 
    $AR -M <<- 'EOF'
CREATE libx265.a
ADDLIB libx265_main.a
ADDLIB libx265_main10.a
ADDLIB libx265_main12.a
SAVE
END
EOF

    upkg_make install &&
    $PREFIX/bin/x265 -V &&
    cd -
    return $?
}

