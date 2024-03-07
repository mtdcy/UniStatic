#!/bin/bash
[ -z $BASH ] && { exec bash "$0" "$@" || exit; }

export LC_ALL=C
export LANG=C
umask 022
set -e # exit on error
#set -x

# source ulib.sh 
source "$(dirname $0)/ulib.sh"

upkg_deps=(
    # basic libs
    zlib bzip2 lzma iconv gnutls
    # audio libs
    soxr lame ogg vorbis amr opus fdk-aac 
    # image libs 
    png gif turbojpeg tiff webp openjpeg 
    # video libs 
    zimg theora vpx openh264 kvazaar x264 x265 xvidcore 
    # text libs 
    fribidi libass 
    # demuxers & muxers 
    xml2 sdl2
    # video postprocessing
    frei0r
    # hwaccels
    libdrm libva OpenCL
)

upkg_build_deps "${upkg_deps[@]}" &&
upkg_build "$UPKG_ROOT/libs/ffmpeg6.sh"
