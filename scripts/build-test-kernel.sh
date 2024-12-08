#!/bin/bash
set -e

WORKDIR="/media/ghost/12B4-F9B2/Software/ghostOS/test-env"
KERNEL_VERSION="5.10.92"
KERNEL_DIR="${WORKDIR}/linux-${KERNEL_VERSION}"

# Download and extract kernel
if [ ! -d "${KERNEL_DIR}" ]; then
    cd "${WORKDIR}"
    wget "https://cdn.kernel.org/pub/linux/kernel/v5.x/linux-${KERNEL_VERSION}.tar.xz"
    tar xf "linux-${KERNEL_VERSION}.tar.xz"
fi

# Configure kernel for Pi Zero W testing
cd "${KERNEL_DIR}"
make ARCH=arm versatile_defconfig
echo "CONFIG_CROSS_COMPILE=\"arm-linux-gnueabi-\"" >> .config
echo "CONFIG_LOCALVERSION=\"-ghost\"" >> .config

# Build kernel
make ARCH=arm CROSS_COMPILE=arm-linux-gnueabi- -j$(nproc)

# Copy kernel to test environment
cp arch/arm/boot/zImage "${WORKDIR}/boot/kernel7.img"

echo "Test kernel built successfully"
