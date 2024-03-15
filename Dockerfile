# syntax=docker/dockerfile:1

FROM    ubuntu:22.04
LABEL   maintainer="mtdcy.chen@gmail.com"

# ENV & ARG variables
ARG MIRROR=""
ARG TZ=Asia/Shanghai

ENV LANG=en_US.UTF-8  
ENV LC_ALL=${LANG}
ENV TZ=${TZ}
ENV DEBIAN_FRONTEND=noninteractive

# prepare #1
RUN test ! -z "${MIRROR}" &&                              \
    sed -e "s|http://archive.ubuntu.com|${MIRROR}|g"      \
        -e "s|http://security.ubuntu.com|${MIRROR}|g"     \
        -i /etc/apt/sources.list;                         \
    apt-get update &&                                     \
    apt-get install -y locales tzdata &&                  \
    dpkg-reconfigure locales &&                           \
    ln -svf /usr/share/zoneinfo/$TZ /etc/localtime &&     \
    echo "$TZ" > /etc/timezone

# prepare #2
RUN apt-get install -y                                    \
        wget curl git                                     \
        xz-utils lzip unzip                               \
        build-essential                                   \
        autoconf libtool pkg-config cmake meson           \
        nasm yasm bison flex                              \
        luajit perl libhttp-daemon-perl                   \
    && apt-get clean                                      \
    && rm -rf /var/lib/apt/lists/*

# use bash as default shell
RUN ln -sfv /bin/bash /bin/sh
