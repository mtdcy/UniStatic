#!/bin/bash
[ -z $BASH ] && { exec bash "$0" "$@" || exit; }

#set -x
set -e # exit on error
umask 022

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
    zimg theora vpx 
    openh264 kvazaar x264 x265      # h264/hevc encoders
    # xvidcore: mpeg4 encoder
    # text libs 
    fribidi libass 
    # demuxers & muxers 
    xml2 sdl2
    # video postprocessing
    frei0r
)

upkg_linux && upkg_deps+=(libdrm libva OpenCL)

upkg_build_deps "${upkg_deps[@]}" &&
upkg_build "$UPKG_ROOT/libs/ffmpeg6.sh"
