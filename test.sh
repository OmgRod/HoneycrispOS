#!/bin/bash
set -e

# Find the generated hybrid ISO file dynamically
ISO_FILE=$(find . -maxdepth 1 -name "honeycrisp-os*.iso" | head -n 1)

if [ -z "$ISO_FILE" ]; then
    echo "Error: No Honeycrisp OS ISO found! Run ./build.sh first."
    exit 1
fi

echo "Launching $ISO_FILE in QEMU..."
qemu-system-x86_64 \
    -enable-kvm \
    -m 4G \
    -cpu host \
    -cdrom "$ISO_FILE" \
    -boot d