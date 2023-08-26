#!/bin/bash

xpkg_lic="GPL/LGPL/BSD"
xpkg_ver=4.1
xpkg_url=https://ffmpeg.org/releases/ffmpeg-$xpkg_ver.tar.bz2 
xpkg_sha=b684fb43244a5c4caae652af9022ed5d85ce15210835bce054a33fb26033a1a5

xpkg_static() {
    xpkg_args=(
        --enable-pic
        --enable-hardcoded-tables
        --disable-stripping
        --extra-ldflags=\"$LDFLAGS\"
        --extra-cflags=\"$CFLAGS\"
        --enable-shared 
        --enable-rpath 
        --enable-static
        --enable-zlib
        --enable-bzlib
        --enable-lzma
        --enable-iconv
        --enable-ffmpeg 
        --enable-ffprobe 
        #--enable-ffplay
        --disable-autodetect # manual control external libraries 
        --enable-decoders --enable-encoders --enable-demuxers --enable-muxers
        --enable-sdl2
        --enable-libsoxr            # audio resampling
        --enable-libopencore-amrnb  # amrnb encoding
        --enable-libopencore-amrwb  # amrwb encoding
        --enable-libmp3lame         # mp3 encoding
        --enable-libvpx             # vp8 & vp9 encoding & decoding
        --enable-libwebp            # webp encoding
        --enable-libvorbis          # vorbis encoding & decoding, ffmpg has native one but experimental
        --enable-libtheora          # enable if you need theora encoding
        --enable-libopus            # opus encoding & decoding, ffmpeg has native one
        --enable-libopenjpeg        # jpeg 2000 encoding & decoding, ffmpeg has native one
        #--enable-libass             # FIXME
        --enable-libopenh264        # h264 encoding
        --enable-libkvazaar         # hevc encoding
        # GPL
        --enable-gpl                # GPL 2.x & 3.0
        --enable-version3           # LGPL 3.0
        --enable-libx264            # h264 encoding
        --enable-libx265            # hevc encoding
        --enable-libxvid            # mpeg4 encoding, ffmpeg has native one
        --enable-frei0r             # frei0r 
        # nonfree -> unredistributable
        --enable-nonfree 
        --enable-libfdk-aac         # aac encoding
        )

        # read kvazaar's README
        xpkg_is_msys && xpkg_is_static && xpkg_args+=(--extra-cflags=-DKVZ_STATIC_LIB) 

        xpkg_is_static && {
            # ffmpeg prefer shared libs, fix bug using extra libs
            xpkg_is_linux && xpkg_args+=(--extra-libs=-lm --extra-libs=-lpthread) 

            xpkg_args+=(--disable-shared --enable-static)
        }


        # platform hw accel
        # https://trac.ffmpeg.org/wiki/HWAccelIntro
        xpkg_is_macos && xpkg_args+=(
            # macOS frameworks for image&audio&video
            --enable-coreimage          # for avfilter
            --enable-audiotoolbox
            --enable-videotoolbox
            --enable-securetransport    # TLS
            --enable-opencl
            --enable-opengl
        )

        xpkg_is_msys && xpkg_args+=(
            --enable-opencl
            --enable-d3d11va
            --enable-dxva2
        )

        xpkg_is_linux && xlog warn "fixme: configure hwaccel for linux" 
        #--enable-opencl
        #--enable-opengl
        #--enable-vdpau
        #--enable-vaapi

        xpkg_configure "${xpkg_args[@]}" --disable-shared &&
        xpkg_make_njobs install || return $?

        # fix libavcodec.pc
        # it's ffmpeg configure's fault
        grep iconv $PKG_CONFIG_PATH/libavcodec.pc || sed -i 's/Libs:.*-llzma/& -liconv/' $PKG_CONFIG_PATH/libavcodec.pc

        return $?
}


#export FFMPEG_SOURCES=`pwd`
## FFmpeg - GPL or LGPL
#ARGS="--prefix=$PREFIX --enable-pic --enable-hardcoded-tables --disable-stripping"
#ARGS+=" --extra-ldflags=\"$LDFLAGS\" --extra-cflags=\"$CFLAGS\""
#if [ $XPKG_SHARED -eq 1 ]; then
#    ARGS+=" --enable-shared --disable-static --enable-rpath"
#else
#    ARGS+=" --disable-shared --enable-static"
#    ARGS+=" --pkg-config-flags=--static"
#
#    # ffmpeg prefer shared libs, fix bug using extra libs
#    if [[ "$OSTYPE" == "linux"* ]]; then
#        ARGS+=" --extra-libs=-lm --extra-libs=-lpthread"
#    fi
#fi
#
## external libraries
##ARGS+=" --enable-openssl"      # FIXME: always using system openssl
#ARGS+=" --enable-zlib"
#ARGS+=" --enable-bzlib"
#ARGS+=" --enable-lzma"
##ARGS+=" --enable-iconv" FIXME: link failed 
#ARGS+=" --enable-ffmpeg"
#ARGS+=" --enable-ffprobe"
#ARGS+=" --enable-ffplay"
## disable-autodetect must define after enable-iconv, or
## it may break the build. it's ffmpeg configure's fault
#ARGS+=" --disable-autodetect"   # manual control external libraries
#ARGS+=" --extra-ldflags=-liconv"
#
#if [ $BUILD_HUGE -eq 1 ]; then
#    ARGS+=" --enable-decoders --enable-encoders --enable-demuxers --enable-muxers"
#    ARGS+=" --enable-sdl2"
#    ARGS+=" --enable-libsoxr"       # audio resampling
#    ARGS+=" --enable-libopencore-amrnb"     # amrnb encoding
#    ARGS+=" --enable-libopencore-amrwb"     # amrwb encoding
#    ARGS+=" --enable-libmp3lame"    # mp3 encoding
#    ARGS+=" --enable-libvpx"        # vp8 & vp9 encoding & decoding
#    ARGS+=" --enable-libwebp"       # webp encoding
#    ARGS+=" --enable-libvorbis"     # vorbis encoding & decoding, ffmpg has native one but experimental
#    ARGS+=" --enable-libtheora"     # enable if you need theora encoding
#    ARGS+=" --enable-libopus"       # opus encoding & decoding, ffmpeg has native one
#    ARGS+=" --enable-libopenjpeg"   # jpeg 2000 encoding & decoding, ffmpeg has native one
#
#    ARGS+=" --enable-libass"       # FIXME
#    if [ $BUILD_GPL -eq 1 ]; then
#        ARGS+=" --enable-gpl"           # GPL 2.x & 3.0
#        ARGS+=" --enable-version3"      # LGPL 3.0
#        ARGS+=" --enable-libx264"       # h264 encoding
#        ARGS+=" --enable-libx265"       # hevc encoding
#        ARGS+=" --enable-libxvid"       # mpeg4 encoding, ffmpeg has native one
#        ARGS+=" --enable-frei0r"        # frei0r 
#    fi
#
#    if [ $BUILD_GPL -eq 0 ]; then
#        ARGS+=" --enable-libopenh264"   # h264 encoding
#        # read kvazaar's README
#        [[ "$OSTYPE" == "msys" && $XPKG_SHARED -eq 0 ]] && ARGS+=" --extra-cflags=-DKVZ_STATIC_LIB"
#        ARGS+=" --enable-libkvazaar"    # hevc encoding
#    fi
#
#    # nonfree -> unredistributable
#    if [ $BUILD_NONFREE -eq 1 ]; then
#        ARGS+=" --enable-nonfree"
#        ARGS+=" --enable-libfdk-aac"    # aac encoding
#    fi
#else
#    #ARGS+=" --disable-programs"
#    # usally for project, output format is known
#    #ARGS+=" --enable-decoders --enable-demuxers --disable-encoders --disable-muxers"
#    # only demuxers & decoders
#    ARGS+=" --enable-decoders --enable-demuxers --enable-encoders --enable-muxers"
#    #ARGS+=" --enable-encoder=aac,libfdk_aac,alac,libmp3lame,libvorbis,flac,libopencore_amrnb,libopencore_amrwb" # audio
#    #ARGS+=" --enable-encoder=libvpx_vp8,libvpx_vp9,libwebp,libx264,libx265,libopenh264,libkvazaar,mpeg4"        # video
#    [[ "$OSTYPE" == "darwin"* ]] && ARGS+=" --enable-encoder=h264_videotoolbox,hevc_videotoolbox"               # hw video
#    ARGS+=" --enable-encoder=ssa,ass"   # subtitle
#    #ARGS+=" --enable-muxer=mov,mp3,mp4,flac,matroska,ogg,wav"   # muxer
#fi
#
## platform hw accel
## https://trac.ffmpeg.org/wiki/HWAccelIntro
#if [[ "$OSTYPE" == "darwin"* ]]; then
#    # macOS frameworks for image&audio&video
#    ARGS+=" --enable-coreimage"         # for avfilter
#    ARGS+=" --enable-audiotoolbox"
#    ARGS+=" --enable-videotoolbox"
#    ARGS+=" --enable-securetransport"   # TLS
#    ARGS+=" --enable-opencl"
#    ARGS+=" --enable-opengl"
#elif [[ "$OSTYPE" == "msys" ]]; then
#    #ARGS+=" --enable-opencl"
#    ARGS+=" --enable-d3d11va"
#    ARGS+=" --enable-dxva2"
#else
#    echo "FIXME: no hwaccel for Linux"
#    # no hwaccel for Linux, as non of them are offical & universal
#    # enable these only for local project usage
#    #ARGS+=" --enable-opencl"
#    #ARGS+=" --enable-opengl"
#    #ARGS+=" --enable-vdpau"
#    #ARGS+=" --enable-vaapi"
#fi
#
## for test
#ARGS+=" --samples=fate-suite/"
#info "ARGS: $ARGS"
#
#cmd="./configure $ARGS"
#info "ffmpeg: $cmd"
#eval $cmd || error "$cmd failed"
#$MAKE -j$XPKG_NJOBS VERBOSE=1 || error "make failed"
#$MAKE install VERBOSE=1 || error "make install failed"
#
## fix libavcodec.pc
## it's ffmpeg configure's fault
#grep iconv $PKG_CONFIG_PATH/libavcodec.pc || sed -i 's/Libs:.*-llzma/& -liconv/' $PKG_CONFIG_PATH/libavcodec.pc
