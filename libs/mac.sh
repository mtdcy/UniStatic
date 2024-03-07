#!/bin/bash

upkg_lic="3-Clause BSD"
upkg_ver=1052
upkg_url=https://monkeysaudio.com/files/MAC_${upkg_ver}_SDK.zip
upkg_sha=3b6c281ba3125c244a3bfa7f4248bef7fedd4bd6a3e2b57f6ec04c1349ef3dbe

upkg_args=(
    -DBUILD_SHARED=OFF
)

upkg_static() {
    upkg_configure -DBUILD_SHARED=OFF && upkg_make_njobs && upkg_make install
}
