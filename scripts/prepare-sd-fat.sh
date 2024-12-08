#!/bin/bash

set -e

# Raspberry Pi firmware version
RASPBERRYPI_FIRMWARE="1.20231025"
WORKDIR="/tmp/ghostos-build"

if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <device>"
    echo "Example: $0 /dev/mmcblk0"
    exit 1
fi

DEVICE=$1
BOOT_SIZE=256 # MB
ROOT_SIZE=1536 # MB

echo "WARNING: This will erase all data on $DEVICE"
read -p "Are you sure you want to continue? (y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 1
fi

# Create temporary work directory
rm -rf "$WORKDIR"
mkdir -p "$WORKDIR"
cd "$WORKDIR"

# Unmount any existing partitions
umount ${DEVICE}* 2>/dev/null || true

# Create partition table
parted -s $DEVICE mklabel msdos

# Create boot partition (FAT32)
parted -s $DEVICE mkpart primary fat32 1MiB ${BOOT_SIZE}MiB
parted -s $DEVICE set 1 boot on

# Create root partition (ext4)
parted -s $DEVICE mkpart primary ext4 ${BOOT_SIZE}MiB 100%

# Format partitions
mkfs.vfat -F 32 ${DEVICE}1
mkfs.ext4 -F ${DEVICE}2

# Mount partitions
mkdir -p mnt/{boot,root}
mount ${DEVICE}1 mnt/boot
mount ${DEVICE}2 mnt/root

# Create basic directory structure
mkdir -p mnt/root/{bin,boot,dev,etc,home,lib,media,mnt,opt,proc,root,run,sbin,srv,sys,tmp,usr,var}
chmod 1777 mnt/root/tmp
chmod 700 mnt/root/root

# Setup boot files
cp -r /media/ghost/12B4-F9B2/Software/ghostOS/boot/* mnt/boot/ || true

# Download Raspberry Pi firmware if needed
if [ ! -f "bootcode.bin" ]; then
    wget https://github.com/raspberrypi/firmware/raw/master/boot/bootcode.bin
    wget https://github.com/raspberrypi/firmware/raw/master/boot/start.elf
    wget https://github.com/raspberrypi/firmware/raw/master/boot/fixup.dat
fi

# Copy Raspberry Pi bootloader files
cp bootcode.bin start.elf fixup.dat mnt/boot/

# Create basic config.txt
cat > mnt/boot/config.txt << EOF
# GhostOS config for Pi Zero W
arm_64bit=0
kernel=kernel7.img
gpu_mem=16
dtoverlay=miniuart-bt
enable_uart=1
EOF

# Create basic cmdline.txt
echo "console=serial0,115200 console=tty1 root=/dev/mmcblk0p2 rootfstype=ext4 elevator=deadline fsck.repair=yes rootwait quiet" > mnt/boot/cmdline.txt

# Unmount
umount mnt/boot mnt/root

echo "SD card prepared successfully!"
echo "Now run build-lfs-pizero.sh to build the system"
