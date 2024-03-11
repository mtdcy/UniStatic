# syntax=docker/dockerfile:1

FROM    ubuntu:22.04
LABEL   maintainer="mtdcy.chen@gmail.com"

# ENV & ARG variables
ARG MIRROR=""
ARG TZ=Asia/Shanghai

ENV TZ=${TZ}
ENV DEBIAN_FRONTEND=noninteractive

# prepare #1
RUN test ! -z "${MIRROR}" &&                              \
    sed -e "s|http://archive.ubuntu.com|${MIRROR}|g"      \
        -e "s|http://security.ubuntu.com|${MIRROR}|g"     \
        -i /etc/apt/sources.list;                         \
    apt-get update &&                                     \
    apt-get install -y tzdata                             \
    ln -svf /usr/share/zoneinfo/$TZ /etc/localtime &&     \
    echo "$TZ" > /etc/timezone

# prepare #2
RUN apt-get install -y                                    \
        build-essential                                   \
        pkg-config                                        \
        m4                                                \
        autoconf                                          \
        libtool                                           \
        cmake                                             \
        meson                                             \
        ninja-build                                       \
        nasm                                              \
        yasm                                              \
        wget                                              \
        curl                                              \
        git                                               \
        xz-utils                                          \
        unzip                                             \
    && apt-get clean                                      \
    && rm -rf /var/lib/apt/lists/*
