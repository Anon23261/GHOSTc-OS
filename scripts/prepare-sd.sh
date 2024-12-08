#!/bin/bash

set -e

# Raspberry Pi firmware version
RASPBERRYPI_FIRMWARE="1.20231025"

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

# Unmount any existing partitions
sudo umount ${DEVICE}* 2>/dev/null || true

# Create partition table
sudo parted -s $DEVICE mklabel msdos

# Create boot partition (FAT32)
sudo parted -s $DEVICE mkpart primary fat32 1MiB ${BOOT_SIZE}MiB
sudo parted -s $DEVICE set 1 boot on

# Create root partition (ext4)
sudo parted -s $DEVICE mkpart primary ext4 ${BOOT_SIZE}MiB 100%

# Format partitions
sudo mkfs.vfat -F 32 ${DEVICE}p1
sudo mkfs.ext4 -F ${DEVICE}p2

# Mount partitions
mkdir -p mnt/{boot,root}
sudo mount ${DEVICE}p1 mnt/boot
sudo mount ${DEVICE}p2 mnt/root

# Copy boot files
sudo cp -r $LFS/boot/* mnt/boot/

# Copy Raspberry Pi bootloader files
sudo cp $LFS/sources/firmware-${RASPBERRYPI_FIRMWARE}/boot/bootcode.bin mnt/boot/
sudo cp $LFS/sources/firmware-${RASPBERRYPI_FIRMWARE}/boot/start.elf mnt/boot/
sudo cp $LFS/sources/firmware-${RASPBERRYPI_FIRMWARE}/boot/fixup.dat mnt/boot/
sudo cp $LFS/sources/firmware-${RASPBERRYPI_FIRMWARE}/boot/start_cd.elf mnt/boot/
sudo cp $LFS/sources/firmware-${RASPBERRYPI_FIRMWARE}/boot/fixup_cd.dat mnt/boot/

# Copy root filesystem
sudo cp -a $LFS/* mnt/root/

# Create config.txt
cat > mnt/boot/config.txt << "EOF"
# GhostOS Pi Zero W configuration
gpu_mem=16
dtparam=audio=on
dtparam=spi=on
dtparam=i2c_arm=on
dtoverlay=miniuart-bt
enable_uart=1

# CPU settings
arm_freq=1000
over_voltage=6
core_freq=400
sdram_freq=450
force_turbo=0

# Video settings
hdmi_force_hotplug=1
hdmi_group=2
hdmi_mode=82
EOF

# Create cmdline.txt
echo "console=serial0,115200 console=tty1 root=/dev/mmcblk0p2 rootfstype=ext4 rootwait quiet init=/sbin/init" > mnt/boot/cmdline.txt

# Create basic wpa_supplicant.conf
cat > mnt/root/etc/wpa_supplicant/wpa_supplicant.conf << "EOF"
ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev
update_config=1
country=US

network={
    ssid="YourWiFiNetwork"
    psk="YourWiFiPassword"
    key_mgmt=WPA-PSK
}
EOF

# Cleanup
sync
sudo umount mnt/boot mnt/root
rm -rf mnt

echo "SD card prepared successfully!"
echo "1. Edit /etc/wpa_supplicant/wpa_supplicant.conf on the SD card to set your WiFi credentials"
echo "2. Insert the SD card into your Pi Zero W and power it on"
echo "3. The system will boot and automatically connect to WiFi"
