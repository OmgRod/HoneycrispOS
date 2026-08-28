FROM debian:bookworm

RUN apt-get update && apt-get install -y \
    live-build \
    debootstrap \
    xorriso \
    squashfs-tools \
    mtools \
    syslinux \
    curl \
    git \
    unzip \
    xz-utils \
    libglu1-mesa \
    libgtk-3-dev \
    clang \
    cmake \
    ninja-build \
    pkg-config \
    && rm -rf /var/lib/apt/lists/*

ENV FLUTTER_ROOT="/usr/local/flutter"
RUN git clone https://github.com/flutter/flutter.git -b stable $FLUTTER_ROOT
ENV PATH="$FLUTTER_ROOT/bin:$FLUTTER_ROOT/bin/cache/dart-sdk/bin:$PATH"

RUN flutter precache --linux

WORKDIR /workspace