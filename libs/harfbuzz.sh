#!/bin/bash
# OpenType text shaping engine

upkg_lic="MIT"
upkg_ver=8.3.0
upkg_url=https://github.com/harfbuzz/harfbuzz/releases/download/$upkg_ver/harfbuzz-$upkg_ver.tar.xz
upkg_sha=109501eaeb8bde3eadb25fab4164e993fbace29c3d775bcaa1c1e58e2f15f847
upkg_dep=(freetype)

# FIXME: missing a lot of depends
upkg_args=(
    --prefix="$PREFIX"
    --buildtype=release
    --default-library=static
    -Dcairo=disabled
    -Dcoretext=disabled
    -Dfreetype=enabled
    -Dglib=disabled
    -Dgobject=disabled
    -Dgraphite=disabled
    -Dicu_builtin="true"
    -Dintrospection=enabled
    -Dtests=disabled
    -Ddocs=disabled
    -Dutilities=disabled
    -Dintrospection=disabled
)

upkg_static() {

    meson setup build "${upkg_args[@]}" &&
    meson compile -C build --verbose &&
    meson install -C build 
}

