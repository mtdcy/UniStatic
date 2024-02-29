#!/bin/bash

upkg_lic="GPL"
upkg_ver=2023.12.14
upkg_url=https://github.com/KhronosGroup/OpenCL-Headers/archive/refs/tags/v$upkg_ver.zip
upkg_zip=OpenCL-Headers-$upkg_ver.zip
upkg_sha=2368105c0531069fe927989505de7d125ec58c55

upkg_static() {
    upkg_configure . && upkg_make install
}
