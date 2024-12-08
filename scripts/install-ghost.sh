#!/bin/bash
set -e

# GhostOS SD Card Installation Script
GHOST_VERSION="1.0.0"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Please run as root${NC}"
    exit 1
fi

# Get SD card device
if [ -z "$1" ]; then
    echo -e "${RED}Usage: $0 <device> (e.g., /dev/sdb)${NC}"
    exit 1
fi

DEVICE="$1"

# Safety checks
check_device() {
    if [ ! -b "$DEVICE" ]; then
        echo -e "${RED}Error: $DEVICE is not a block device${NC}"
        exit 1
    fi
    
    if mount | grep "on / " | grep -q "$DEVICE"; then
        echo -e "${RED}Error: $DEVICE appears to be the system drive!${NC}"
        exit 1
    fi
    
    echo -e "${RED}WARNING: This will erase ALL data on $DEVICE${NC}"
    echo -e "${RED}Type 'YES' in capitals to continue${NC}"
    read confirm
    if [ "$confirm" != "YES" ]; then
        echo "Operation cancelled"
        exit 1
    fi
}

# Create partitions
create_partitions() {
    echo -e "${GREEN}Creating partitions...${NC}"
    
    # Unmount any existing partitions
    umount ${DEVICE}* 2>/dev/null || true
    
    # Create partition table
    parted -s ${DEVICE} mklabel msdos
    
    # Create boot partition (256MB FAT32)
    parted -s ${DEVICE} mkpart primary fat32 1MiB 257MiB
    parted -s ${DEVICE} set 1 boot on
    
    # Create root partition (rest of the space, ext4)
    parted -s ${DEVICE} mkpart primary ext4 257MiB 100%
    
    # Wait for device nodes
    sleep 2
    
    # Format partitions
    mkfs.vfat -F 32 ${DEVICE}1
    mkfs.ext4 -F ${DEVICE}2
}

# Install system
install_system() {
    echo -e "${GREEN}Installing GhostOS...${NC}"
    
    # Mount partitions
    mkdir -p /mnt/ghost/{boot,root}
    mount ${DEVICE}1 /mnt/ghost/boot
    mount ${DEVICE}2 /mnt/ghost/root
    
    # Copy boot files
    cp -r build/boot/* /mnt/ghost/boot/
    
    # Copy root filesystem
    cp -a build/root/* /mnt/ghost/root/
    
    # Create necessary directories
    mkdir -p /mnt/ghost/root/{proc,sys,dev,run,tmp}
    chmod 1777 /mnt/ghost/root/tmp
    
    # Create fstab
    cat > /mnt/ghost/root/etc/fstab << EOF
/dev/mmcblk0p1  /boot           vfat    defaults          0       2
/dev/mmcblk0p2  /              ext4    defaults,noatime  0       1
proc            /proc           proc    defaults          0       0
sysfs           /sys            sysfs   defaults          0       0
devpts          /dev/pts        devpts  defaults,gid=5,mode=620   0       0
tmpfs           /run            tmpfs   defaults          0       0
tmpfs           /tmp            tmpfs   defaults          0       0
EOF

    # Create first boot script
    cat > /mnt/ghost/root/etc/init.d/firstboot << EOF
#!/bin/sh
# First boot configuration script

# Initialize GhostC
/usr/local/lib/ghostc/ghostc-init --setup

# Enable stealth mode if configured
if grep -q "GHOST_STEALTH_MODE=1" /etc/ghost/config; then
    /usr/local/lib/ghostc/ghostc-stealth --enable
fi

# Remove this script
rm /etc/init.d/firstboot
EOF
    chmod +x /mnt/ghost/root/etc/init.d/firstboot
    
    # Sync and unmount
    sync
    umount /mnt/ghost/boot
    umount /mnt/ghost/root
    rm -rf /mnt/ghost
}

# Main installation process
main() {
    echo -e "${BLUE}GhostOS Installation Script v${GHOST_VERSION}${NC}"
    echo -e "${BLUE}Target device: ${DEVICE}${NC}"
    
    # Run safety checks
    check_device
    
    # Perform installation
    create_partitions
    install_system
    
    echo -e "${GREEN}Installation complete!${NC}"
    echo -e "${BLUE}You can now insert the SD card into your Raspberry Pi Zero W${NC}"
}

# Run installation
main
