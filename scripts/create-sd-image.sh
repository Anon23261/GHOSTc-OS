#!/bin/bash

# Create SD card image for GhostOS
set -e

# Configuration
IMAGE_NAME="ghostos.img"
IMAGE_SIZE="4G"
BOOT_SIZE="256M"
ROOT_SIZE="3.7G"

echo "Creating GhostOS SD card image..."

# Create empty image
dd if=/dev/zero of=$IMAGE_NAME bs=1 count=0 seek=$IMAGE_SIZE

# Set up loop device
LOOP_DEV=$(losetup -f)
sudo losetup $LOOP_DEV $IMAGE_NAME

# Create partition table
sudo parted $LOOP_DEV mklabel msdos
sudo parted $LOOP_DEV mkpart primary fat32 1MiB $BOOT_SIZE
sudo parted $LOOP_DEV mkpart primary ext4 $BOOT_SIZE 100%

# Set up loop devices for partitions
BOOT_DEV="${LOOP_DEV}p1"
ROOT_DEV="${LOOP_DEV}p2"

# Format partitions
sudo mkfs.vfat -F 32 $BOOT_DEV
sudo mkfs.ext4 $ROOT_DEV

# Mount partitions
mkdir -p mnt/{boot,root}
sudo mount $BOOT_DEV mnt/boot
sudo mount $ROOT_DEV mnt/root

# Copy LFS system
echo "Copying LFS system to image..."
sudo cp -av $LFS/* mnt/root/

# Set up boot files
echo "Setting up boot files..."
sudo cp mnt/root/boot/* mnt/boot/

# Create boot config
cat > mnt/boot/config.txt << "EOF"
# Raspberry Pi Zero W config
dtoverlay=dwc2
gpu_mem=128
start_x=1
enable_uart=1

# Display settings
hdmi_force_hotplug=1
hdmi_group=2
hdmi_mode=82
EOF

# Create cmdline.txt
echo "console=serial0,115200 console=tty1 root=/dev/mmcblk0p2 rootfstype=ext4 elevator=deadline fsck.repair=yes rootwait" > mnt/boot/cmdline.txt

# Set up Ghost AI autostart
mkdir -p mnt/root/etc/systemd/system
cat > mnt/root/etc/systemd/system/ghost.service << "EOF"
[Unit]
Description=Ghost AI Assistant
After=network.target

[Service]
Type=simple
ExecStart=/opt/ghost/bin/ghost_ai
Restart=always
User=root

[Install]
WantedBy=multi-user.target
EOF

# Enable services
chroot mnt/root systemctl enable ghost.service

# Clean up
sudo umount mnt/boot mnt/root
sudo losetup -d $LOOP_DEV
rm -rf mnt

echo "SD card image created successfully: $IMAGE_NAME"
echo "Flash it to your SD card using:"
echo "sudo dd if=$IMAGE_NAME of=/dev/sdX bs=4M status=progress"
