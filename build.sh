#!/bin/bash
set -e

echo "Building Flutter shell..."
cd honeycrisp_shell
flutter build linux --release
cd ..

echo "Injecting Flutter bundle into live-build..."
mkdir -p config/includes.chroot/usr/lib/honeycrisp-shell
rm -rf config/includes.chroot/usr/lib/honeycrisp-shell/*
cp -r honeycrisp_shell/build/linux/x64/release/bundle/* config/includes.chroot/usr/lib/honeycrisp-shell/

chmod +x config/includes.chroot/usr/lib/honeycrisp-shell/honeycrisp_shell

mkdir -p config/includes.chroot/usr/local/bin
ln -sf /usr/lib/honeycrisp-shell/honeycrisp_shell config/includes.chroot/usr/local/bin/honeycrisp-shell

echo "Building Honeycrisp OS Docker image..."
docker build -t honeycrisp-builder .

echo "Cleaning previous build stages (keeping cache for speed)..."
docker run --rm --privileged -v "$(pwd):/workspace" honeycrisp-builder lb clean || true

echo "Initializing live-build configuration..."
docker run --rm -v "$(pwd):/workspace" honeycrisp-builder lb config \
    --distribution bookworm \
    --architectures amd64 \
    --image-name honeycrisp-os

echo "Starting ISO compilation inside Docker..."
docker run --rm --privileged -v "$(pwd):/workspace" honeycrisp-builder lb build

echo "Build complete! Your ISO is ready."