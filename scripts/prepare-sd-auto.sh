#!/bin/bash

set -e
set -x

# Raspberry Pi firmware version
RASPBERRYPI_FIRMWARE="1.20231025"
WORKDIR="/tmp/ghostos-build"
DEVICE="/dev/sda"

# Create temporary work directory
rm -rf "$WORKDIR"
mkdir -p "$WORKDIR"
cd "$WORKDIR"

# Unmount any existing partitions
umount ${DEVICE}* 2>/dev/null || true

# Create partition table
parted -s $DEVICE mklabel msdos

# Create boot partition (FAT32)
parted -s $DEVICE mkpart primary fat32 1MiB 256MiB
parted -s $DEVICE set 1 boot on

# Create root partition (ext4)
parted -s $DEVICE mkpart primary ext4 256MiB 100%

# Wait for device nodes
sleep 3
partprobe $DEVICE
sleep 2

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

# Download Raspberry Pi firmware
wget https://github.com/raspberrypi/firmware/raw/master/boot/bootcode.bin
wget https://github.com/raspberrypi/firmware/raw/master/boot/start.elf
wget https://github.com/raspberrypi/firmware/raw/master/boot/fixup.dat

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
