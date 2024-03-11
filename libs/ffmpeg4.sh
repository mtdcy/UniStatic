#!/bin/bash
# 
# DEPRECATED: ffmpeg requires SDL2 < 2.1.0

upkg_lic="GPL/LGPL/BSD"
upkg_ver=4.1
upkg_url=https://ffmpeg.org/releases/ffmpeg-$upkg_ver.tar.bz2 
upkg_sha=b684fb43244a5c4caae652af9022ed5d85ce15210835bce054a33fb26033a1a5

upkg_dep=(
    # basic libs
    zlib bzip2 lzma iconv
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
    xml2
    # video postprocessing
    frei0r
)

upkg_linux && upkg_dep+=(gnutls libdrm libva OpenCL)

# ENVs
FFMPEG_GPL=${FFMPEG_GPL:-1}
FFMPEG_NONFREE=${FFMPEG_NONFREE:-1}
FFMPEG_HWACCEL=${FFMPEG_HWACCEL:-0}
FFMPEG_HUGE=${FFMPEG_HUGE:-1}

upkg_static() {
    upkg_args=(
        --cc=\"$CC\"
        --enable-pic
        --enable-pthreads
        --enable-hardcoded-tables
        --extra-version=UniStatic
        # use extra- to avoid override default flags
        --extra-cflags=\"$CFLAGS\" 
        --extra-cxxflags=\"$CXXFLAGS\"
        --extra-ldflags=\"$LDFLAGS\"
        #--disable-stripping        # result in larger size
        #--enable-shared 
        #--enable-rpath 
        --enable-static
        --enable-zlib
        --enable-bzlib
        --enable-lzma
        --enable-iconv --extra-libs=-liconv
        --enable-libzimg
        --enable-ffmpeg 
        --enable-ffprobe 
        --disable-ffplay            #--enable-ffplay
        --disable-autodetect        # manual control external libraries
        --disable-htmlpages
        --enable-decoders 
        --enable-encoders
        --enable-demuxers
        --enable-muxers
        #--enable-sdl2              # our sdl2 are too new for ffmpeg4
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
        --enable-libopenh264        # h264 encoding
        --enable-libkvazaar         # hevc encoding
        --enable-libass             # ass subtitles
    )

    # GPL
    [ $FFMPEG_GPL -ne 0 ] && {
        upkg_args+=(
            --enable-gpl            # GPL 2.x & 3.0
            --enable-version3       # LGPL 3.0
            --enable-libx264        # h264 encoding
            --enable-libx265        # hevc encoding
            --enable-libxvid        # mpeg4 encoding, ffmpeg has native one
            --enable-frei0r         # frei0r 
        )
        upkg_args=(${upkg_args[@]/--enable-openssl/})
        upkg_args=(${upkg_args[@]/--enable-libtls/})
    }

    # nonfree -> unredistributable
    [ $FFMPEG_NONFREE -ne 0 ] && upkg_args+=(
        --enable-nonfree 
        --enable-libfdk-aac         # aac encoding
    )

    # static linked
    upkg_args+=(
        --disable-shared 
        --enable-static
        --pkg-config-flags=\"--static\"
    )
    
    upkg_linux && upkg_args+=(
        # ffmpeg prefer shared libs, fix bug using extra libs
        --extra-libs=\"-lm -lpthread\"
        --enable-gnutls
        --enable-libdrm 
        --enable-linux-perf
    )
    
    # always enable hwaccel for macOS
    upkg_darwin && upkg_args+=(
        # macOS frameworks for image&audio&video
        --enable-coreimage          # for avfilter
        --enable-audiotoolbox
        --enable-videotoolbox
        --enable-securetransport    # TLS
        --enable-opencl
        --enable-opengl
    )

    upkg_msys && upkg_args+=(
        # read kvazaar's README
        --extra-cflags=-DKVZ_STATIC_LIB
    ) 

    # platform hw accel
    # https://trac.ffmpeg.org/wiki/HWAccelIntro
    [ $FFMPEG_HWACCEL -ne 0 ] && {
        upkg_linux && upkg_args+=(
            #--enable-opencl
            #--enable-opengl
            #--enable-vdpau
            --enable-vaapi
        )

        upkg_msys && upkg_args+=(
            --enable-opencl
            --enable-d3d11va
            --enable-dxva2
        )
    }

    # work arrounds:
    upkg_linux && sed 's/-lsoxr/& -lm/g;s/-lxvidcore/& -lm/g' -i configure

    upkg_configure &&
    upkg_make_njobs &&
    # fix libavcodec.pc
    sed -i 's/Libs.private:.*$/& -liconv/' libavcodec/libavcodec.pc &&
    # install libs and headers only for the newest version
    #upkg_make install-libs install-headers &&
    install -v -s -m 755 ffmpeg  "$PREFIX/bin/ffmpeg4" &&
    install -v -s -m 755 ffprobe "$PREFIX/bin/ffprobe4"
}
