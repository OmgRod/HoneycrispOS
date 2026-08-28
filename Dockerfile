FROM debian:bookworm

# Install live-build, debootstrap, and essential build utilities
RUN apt-get update && apt-get install -y \
    live-build \
    debootstrap \
    xorriso \
    squashfs-tools \
    mtools \
    syslinux \
    && rm -rf /var/lib/apt/lists/*

# Set the working directory inside the container
WORKDIR /workspace