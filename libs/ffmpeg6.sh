#!/bin/bash

upkg_lic="GPL/LGPL/BSD"
upkg_ver=6.1.1
upkg_url=https://ffmpeg.org/releases/ffmpeg-$upkg_ver.tar.xz
upkg_sha=8684f4b00f94b85461884c3719382f1261f0d9eb3d59640a1f4ac0873616f968

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
        --host-cflags=\"$CFLAGS\" 
        --host-ldflags=\"$LDFLAGS\"
        --extra-ldflags=-liconv     # static libavcodec needs this
        #--disable-stripping        # result in larger size
        #--enable-shared 
        #--enable-rpath 
        --enable-static
        --enable-zlib
        --enable-bzlib
        --enable-lzma
        --enable-iconv
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
    
    # ffmpeg prefer shared libs, fix bug using extra libs
    #upkg_linux && upkg_args+=(--extra-libs=-lm --extra-libs=-lpthread) 
    upkg_linux && upkg_args+=(
        --extra-ldflags=\"-lm -lpthread\"
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

    upkg_configure --disable-shared &&
    upkg_make_njobs &&
    # fix libavcodec.pc
    sed -i 's/Libs.private:.*$/& -liconv/' libavcodec/libavcodec.pc &&
    # install libs headers progs
    upkg_make install &&
    # install all tools
    upkg_make alltools &&
    for x in tools/*; do 
        [ -x "$x" ] && install -v -s -m 755 "$x" "$PREFIX/bin" || true
    done
}
