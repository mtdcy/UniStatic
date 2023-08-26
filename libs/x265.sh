#!/bin/bash
# GPL

xpkg_lic="GPL"
xpkg_ver=3.0
xpkg_url=https://bitbucket.org/multicoreware/x265/downloads/x265_$xpkg_ver.tar.gz
xpkg_sha=c5b9fc260cabbc4a81561a448f4ce9cad7218272b4011feabc3a6b751b2f0662


xpkg_static() {
    xpkg_args=(

        )

    xpkg_args_high=(
        -DHIGH_BIT_DEPTH=ON 
        -DEXPORT_C_API=OFF 
        -DENABLE_CLI=OFF 
        -DENABLE_SHARED=OFF
        )

    # build high bits always as static
    mkdir -p {8bit,10bit,12bit}
    # 12 bit
    cd 12bit 
    xpkg_configure "${xpkg_args[@]}" "${xpkg_args_high[@]}" -DMAIN12=ON ../source && 
    xpkg_make_njobs x265-static || return $?
    cd -

    # 10bit
    cd 10bit 
    xpkg_configure "${xpkg_args[@]}" "${xpkg_args_high[@]}" -DMAIN10=ON ../source && 
    xpkg_make_njobs x265-static || return $?
    cd -

    # 8bit
    cd 8bit
    xpkg_is_static && 
        xpkg_args+=(-DENABLE_SHARED=OFF) ||
        xpkg_args+=(-DENABLE_SHARED=ON)

    # prepare high bit static libs
    ln -svf ../12bit/libx265.a libx265_main12.a 
    ln -svf ../10bit/libx265.a libx265_main10.a 

    xpkg_configure "${xpkg_args[@]}" \
        -DEXTRA_LIB=\"x265_main12.a\;x265_main10.a\" \
        -DEXTRA_LINK_FLAGS=-L. \
        -DLINKED_12BIT=ON \
        -DLINKED_10BIT=ON \
        ../source &&
    xpkg_make_njobs x265-static &&
    mv libx265.a libx265_main.a || return $?

    xpkg_is_macos && 
        libtool -static -o libx265.a libx265_main.a libx265_main10.a libx265_main12.a ||
        $AR -M <<- 'EOF'
CREATE libx265.a
ADDLIB libx265_main.a
ADDLIB libx265_main10.a
ADDLIB libx265_main12.a
SAVE
END
EOF

    xpkg_make install && cd - 
    #$PREFIX/bin/x265 -V 
    return $?
}

