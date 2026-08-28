#!/bin/bash
set -e

echo "Building Flutter shell..."
cd honeycrisp_shell
flutter build linux --release
cd ..

echo "Injecting Flutter bundle into live-build..."
mkdir -p config/includes.chroot/usr/lib/honeycrisp_shell
rm -rf config/includes.chroot/usr/lib/honeycrisp_shell/*
cp -r honeycrisp_shell/build/linux/x64/release/bundle/* config/includes.chroot/usr/lib/honeycrisp_shell/

chmod +x config/includes.chroot/usr/lib/honeycrisp_shell/honeycrisp_shell

mkdir -p config/includes.chroot/usr/local/bin
ln -sf /usr/lib/honeycrisp_shell/honeycrisp_shell config/includes.chroot/usr/local/bin/honeycrisp_shell

echo "Building Honeycrisp OS Docker image..."
docker build -t honeycrisp-builder .

echo "Performing a clean wipe of old build cache..."
docker run --rm --privileged -v "$(pwd):/workspace" honeycrisp-builder lb clean --all || true

echo "Initializing live-build configuration..."
docker run --rm -v "$(pwd):/workspace" honeycrisp-builder lb config \
    --distribution bookworm \
    --architectures amd64 \
    --image-name honeycrisp-os

echo "Starting ISO compilation inside Docker..."
docker run --rm --privileged -v "$(pwd):/workspace" honeycrisp-builder lb build

echo "Build complete! Your ISO is ready."