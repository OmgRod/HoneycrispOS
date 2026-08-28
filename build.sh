#!/bin/bash
set -e

ARCH=$(uname -m)
if [ "$ARCH" = "x86_64" ]; then
    LB_ARCH="amd64"
    FLUTTER_ARCH="x64"
elif [ "$ARCH" = "aarch64" ] || [ "$ARCH" = "arm64" ]; then
    LB_ARCH="arm64"
    FLUTTER_ARCH="arm64"
else
    echo "Unsupported architecture: $ARCH"
    exit 1
fi

echo "Detected architecture: $ARCH (Targeting: $LB_ARCH)"

sudo rm -rf cache/bootstrap chroot .build tmp .lock

echo "Building Honeycrisp OS Docker image..."
docker build -t honeycrisp-builder .

echo "Cleaning old Flutter build artifacts to clear stale CMake caches..."
rm -rf honeycrisp_shell/build honeycrisp_shell/.dart_tool

echo "Building Flutter shell inside the Bookworm Docker environment..."
docker run --rm -v "$(pwd):/workspace" -w /workspace/honeycrisp_shell honeycrisp-builder flutter build linux --release

echo "Injecting Flutter bundle into live-build..."
BUNDLE_PATH="honeycrisp_shell/build/linux/$FLUTTER_ARCH/release/bundle"

mkdir -p config/includes.chroot/usr/lib/honeycrisp_shell
rm -rf config/includes.chroot/usr/lib/honeycrisp_shell/*
cp -r "$BUNDLE_PATH"/* config/includes.chroot/usr/lib/honeycrisp_shell/

chmod +x config/includes.chroot/usr/lib/honeycrisp_shell/honeycrisp_shell

mkdir -p config/includes.chroot/usr/local/bin
ln -sf /usr/lib/honeycrisp_shell/honeycrisp_shell config/includes.chroot/usr/local/bin/honeycrisp_shell

echo "Enabling Honeycrisp shell systemd service..."
mkdir -p config/includes.chroot/etc/systemd/system/graphical.target.wants
ln -sf /etc/systemd/system/honeycrisp-shell.service config/includes.chroot/etc/systemd/system/graphical.target.wants/honeycrisp-shell.service

echo "Performing a deep wipe of all local live-build caches and chroot..."
docker run --rm --privileged -v "$(pwd):/workspace" honeycrisp-builder bash -c "rm -rf cache/bootstrap chroot .build" || true

echo "Initializing live-build configuration..."
docker run --rm -v "$(pwd):/workspace" honeycrisp-builder lb config \
    --distribution bookworm \
    --architectures "$LB_ARCH" \
    --image-name "honeycrisp-os-$LB_ARCH"

echo "Starting ISO compilation inside Docker..."
docker run --rm --privileged -v "$(pwd):/workspace" honeycrisp-builder lb build

echo "Build complete! Your ISO is ready."