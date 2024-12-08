#!/bin/bash

set -e

# Configuration
IMAGE_NAME="ghostos-pizero.img"
BOOT_SIZE=256 # MB
ROOT_SIZE=1024 # MB

# Create disk image
create_image() {
    dd if=/dev/zero of=$IMAGE_NAME bs=1M count=$((BOOT_SIZE + ROOT_SIZE))
    
    # Create partition table
    parted -s $IMAGE_NAME mklabel msdos
    parted -s $IMAGE_NAME mkpart primary fat32 1MiB ${BOOT_SIZE}MiB
    parted -s $IMAGE_NAME mkpart primary ext4 ${BOOT_SIZE}MiB 100%
    
    # Setup loop device
    LOOP_DEV=$(sudo losetup -f --show $IMAGE_NAME)
    sudo partprobe $LOOP_DEV
    
    # Format partitions
    sudo mkfs.vfat -F 32 ${LOOP_DEV}p1
    sudo mkfs.ext4 ${LOOP_DEV}p2
    
    # Mount partitions
    mkdir -p mnt/{boot,root}
    sudo mount ${LOOP_DEV}p1 mnt/boot
    sudo mount ${LOOP_DEV}p2 mnt/root
}

# Install bootloader and kernel
install_boot_files() {
    # Copy Raspberry Pi firmware files
    sudo cp bootloader/* mnt/boot/
    
    # Copy kernel and device tree
    sudo cp $LFS/boot/zImage mnt/boot/kernel.img
    sudo cp $LFS/boot/bcm2835-rpi-zero-w.dtb mnt/boot/
    
    # Create minimal config.txt
    cat > mnt/boot/config.txt << "EOF"
# GhostOS Pi Zero W configuration
gpu_mem=16
dtoverlay=miniuart-bt
enable_uart=1
EOF

    # Create minimal cmdline.txt
    echo "console=serial0,115200 console=tty1 root=/dev/mmcblk0p2 rootfstype=ext4 rootwait quiet init=/sbin/init" > mnt/boot/cmdline.txt
}

# Install root filesystem
install_root_fs() {
    # Copy LFS root
    sudo cp -a $LFS/* mnt/root/
    
    # Create necessary directories
    sudo mkdir -p mnt/root/{dev,proc,sys,run}
    
    # Setup minimal network configuration
    cat > mnt/root/etc/network/interfaces << "EOF"
auto lo
iface lo inet loopback

allow-hotplug wlan0
iface wlan0 inet dhcp
    wpa-conf /etc/wpa_supplicant/wpa_supplicant.conf
EOF
}

# Main function
main() {
    echo "Creating GhostOS image for Pi Zero W..."
    create_image
    install_boot_files
    install_root_fs
    
    # Cleanup
    sudo umount mnt/boot mnt/root
    sudo losetup -d $LOOP_DEV
    rm -rf mnt
    
    echo "GhostOS image created successfully: $IMAGE_NAME"
    echo "You can now flash this image to your SD card using:"
    echo "dd if=$IMAGE_NAME of=/dev/mmcblk0 bs=4M status=progress"
}

main "$@"
