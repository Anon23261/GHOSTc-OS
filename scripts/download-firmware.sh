#!/bin/bash

set -e

# Check if LFS is set
if [ -z "$LFS" ]; then
    echo "Error: LFS environment variable is not set"
    echo "Please set it first:"
    echo "export LFS=/path/to/your/lfs/directory"
    exit 1
fi

# Firmware version
RASPBERRYPI_FIRMWARE="1.20231025"
FIRMWARE_DIR="$LFS/sources/firmware-${RASPBERRYPI_FIRMWARE}"

# Create directories if they don't exist
sudo mkdir -p "$FIRMWARE_DIR"
sudo mkdir -p "$FIRMWARE_DIR/boot"
sudo chown -R $(whoami):$(whoami) "$FIRMWARE_DIR"

echo "Downloading Raspberry Pi firmware version ${RASPBERRYPI_FIRMWARE}..."

# Download essential bootloader files
wget -P "$FIRMWARE_DIR/boot" https://github.com/raspberrypi/firmware/raw/master/boot/bootcode.bin
wget -P "$FIRMWARE_DIR/boot" https://github.com/raspberrypi/firmware/raw/master/boot/start.elf
wget -P "$FIRMWARE_DIR/boot" https://github.com/raspberrypi/firmware/raw/master/boot/fixup.dat
wget -P "$FIRMWARE_DIR/boot" https://github.com/raspberrypi/firmware/raw/master/boot/start_cd.elf
wget -P "$FIRMWARE_DIR/boot" https://github.com/raspberrypi/firmware/raw/master/boot/fixup_cd.dat

# Make the files executable
chmod +x "$FIRMWARE_DIR/boot/"*

echo "Firmware files downloaded successfully to ${FIRMWARE_DIR}/boot/"
ls -l "$FIRMWARE_DIR/boot/"
