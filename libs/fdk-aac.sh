#!/bin/bash

upkg_lic="Apache-2.0"
upkg_ver=2.0.2
upkg_url=https://downloads.sourceforge.net/project/opencore-amr/fdk-aac/fdk-aac-$upkg_ver.tar.gz
upkg_sha=829b6b89eef382409cda6857fd82af84fabb63417b08ede9ea7a553f811cb79e

upkg_args=(
    --disable-dependency-tracking
    --disable-debug
    --disable-example
    --disable-shared 
    --enable-static
)

upkg_static() {
    upkg_configure && upkg_make_njobs && upkg_make install && upkg_make_test check
}
