#!/bin/bash
[ -z $BASH ] && { exec bash "$0" "$@" || exit; }

export LC_ALL=C
export LANG=C
umask 022
set -e # exit on error
set -x

# source xlib.sh 
XPKG_ROOT=$(dirname $(readlink -f "$0"))
source "$XPKG_ROOT/xlib.sh"

# prebuilts / PREFIX
export PREFIX="$XPKG_ROOT/prebuilts/$(gcc -dumpmachine)"
mkdir -pv "$PREFIX"

# host compile
# TODO: cross compile
TARGET=$(gcc -dumpmachine)
mkdir -pv out/$TARGET 
cd out/$target 

xpkg_deps=(
    # basic libs
    iconv zlib bzip2 lzma
    # audio libs
    soxr lame ogg vorbis amr opus fdk-aac 
    # image libs 
    png gif turbojpeg tiff webp openjpeg 
    # video libs 
    theora vpx openh264 kvazaar x264 x265 xvidcore 
    # text libs 
    hurfbuzz fribidi ass 
    # demuxers & muxers 
    xml2 sdl2
    # video postprocessing
    frei0r 
)

xpkg_build_deps "${xpkg_deps[@]}" 

xpkg_build "$XPKG_ROOT/build/ffmpeg.sh"
