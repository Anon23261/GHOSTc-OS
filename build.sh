#!/bin/bash
set -e

# GhostOS Build System
GHOST_VERSION="1.0.0"
BUILD_DIR="build"
GHOST_ROOT="$(pwd)"
CROSS_COMPILE="arm-linux-gnueabi-"
KERNEL_VERSION="5.10.92"

# Colors for output: colors text
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}Building GhostOS v${GHOST_VERSION}${NC}"
echo -e "${BLUE}Target: Raspberry Pi Zero W${NC}"

# Create build directory structure
mkdir -p ${BUILD_DIR}/{boot,root,toolchain,kernel}
mkdir -p ${BUILD_DIR}/root/{bin,sbin,lib,usr/local/lib/ghostc,etc/ghost}

# Build kernel
build_kernel() {
    echo -e "${GREEN}Building Linux kernel ${KERNEL_VERSION}...${NC}"
    cd ${BUILD_DIR}/kernel
    
    if [ ! -f "linux-${KERNEL_VERSION}.tar.xz" ]; then
        wget "https://cdn.kernel.org/pub/linux/kernel/v5.x/linux-${KERNEL_VERSION}.tar.xz"
        tar xf "linux-${KERNEL_VERSION}.tar.xz"
    fi
    
    cd "linux-${KERNEL_VERSION}"
    make ARCH=arm bcm2835_defconfig
    
    # Enable required modules for Pi Zero W
    cat >> .config << EOF
CONFIG_WIRELESS=y
CONFIG_CFG80211=y
CONFIG_MAC80211=y
CONFIG_RFKILL=y
CONFIG_BRCMFMAC=y
CONFIG_SPI=y
CONFIG_SPI_BCM2835=y
CONFIG_GPIO_BCM2835=y
CONFIG_GPIO_SYSFS=y
CONFIG_CRYPTO_SHA256=y
CONFIG_CRYPTO_AES=y
EOF
    
    make ARCH=arm CROSS_COMPILE=${CROSS_COMPILE} -j$(nproc) zImage modules dtbs
    
    # Install kernel and modules
    INSTALL_MOD_PATH=${GHOST_ROOT}/${BUILD_DIR}/root make ARCH=arm CROSS_COMPILE=${CROSS_COMPILE} modules_install
    cp arch/arm/boot/zImage ${GHOST_ROOT}/${BUILD_DIR}/boot/kernel7.img
    cp arch/arm/boot/dts/bcm2835-rpi-zero-w.dtb ${GHOST_ROOT}/${BUILD_DIR}/boot/
}

# Build GhostC components
build_ghostc() {
    echo -e "${GREEN}Building GhostC components...${NC}"
    
    # Create GhostC system files
    mkdir -p ${BUILD_DIR}/root/usr/local/lib/ghostc
    mkdir -p ${BUILD_DIR}/root/usr/local/include/ghostc
    
    # Copy GhostC core files
    cp -r src/ghost/src/ghostc/* ${BUILD_DIR}/root/usr/local/lib/ghostc/
    cp -r src/ghost/include/ghostc/* ${BUILD_DIR}/root/usr/local/include/ghostc/
    
    # Make scripts executable
    chmod +x ${BUILD_DIR}/root/usr/local/lib/ghostc/*
    
    # Create GhostC configuration
    cat > ${BUILD_DIR}/root/etc/ghost/config << EOF
# GhostC System Configuration
GHOST_VERSION="${GHOST_VERSION}"
GHOST_NEURAL_ENABLE=1
GHOST_SECURE_MODE=1
GHOST_STEALTH_MODE=1
GHOST_GPIO_ENABLE=1

# Hardware Configuration
GHOST_DEVICE="pi-zero-w"
GHOST_CPU_FREQ=1000
GHOST_GPU_MEM=16

# Network Configuration
GHOST_NETWORK_STEALTH=1
GHOST_WIFI_MONITOR=1
EOF
}

# Prepare boot files
prepare_boot() {
    echo -e "${GREEN}Preparing boot files...${NC}"
    
    # Download Raspberry Pi firmware files if not exists
    cd ${BUILD_DIR}/boot
    if [ ! -f "bootcode.bin" ]; then
        wget https://github.com/raspberrypi/firmware/raw/master/boot/bootcode.bin
        wget https://github.com/raspberrypi/firmware/raw/master/boot/start.elf
        wget https://github.com/raspberrypi/firmware/raw/master/boot/fixup.dat
    fi
    
    # Create boot config
    cat > config.txt << EOF
# GhostOS Boot Configuration
arm_64bit=0
kernel=kernel7.img
gpu_mem=16
dtoverlay=miniuart-bt
enable_uart=1

# CPU Configuration
arm_freq=1000
over_voltage=0
force_turbo=0

# Temperature Protection
temp_limit=85
temp_soft_limit=80

# Hardware Configuration
dtparam=spi=on
dtparam=i2c_arm=on
dtparam=audio=off

# Stealth Mode Settings
dtoverlay=disable-bt
dtoverlay=pi3-disable-wifi
EOF

    # Create cmdline.txt
    echo "console=serial0,115200 console=tty1 root=/dev/mmcblk0p2 rootfstype=ext4 elevator=deadline fsck.repair=yes rootwait quiet loglevel=3" > cmdline.txt
}

# Main build process
main() {
    echo -e "${GREEN}Starting GhostOS build process...${NC}"
    
    # Check for required tools
    command -v ${CROSS_COMPILE}gcc >/dev/null 2>&1 || { echo -e "${RED}Error: Cross compiler not found. Install arm-linux-gnueabi-gcc${NC}" >&2; exit 1; }
    
    # Build components
    build_kernel
    build_ghostc
    prepare_boot
    
    echo -e "${GREEN}Build complete!${NC}"
    echo -e "${BLUE}Output available in ${BUILD_DIR}${NC}"
}

# Run build
main
