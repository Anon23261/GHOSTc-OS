#!/bin/bash

set -e

KERNEL_VERSION="6.1"  # Latest stable LTS kernel
BUILD_DIR="/media/ghost/12B4-F9B2/Software/ghostOS/build/kernel"
KERNEL_SOURCE="https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-${KERNEL_VERSION}.tar.xz"

# Create build directory
mkdir -p ${BUILD_DIR}
cd ${BUILD_DIR}

# Download kernel source if not exists
if [ ! -f "linux-${KERNEL_VERSION}.tar.xz" ]; then
    wget ${KERNEL_SOURCE}
fi

# Extract kernel
if [ ! -d "linux-${KERNEL_VERSION}" ]; then
    tar xf linux-${KERNEL_VERSION}.tar.xz
fi

cd linux-${KERNEL_VERSION}

# Copy our custom kernel config
cp ../../config/kernel.config .config

# Build kernel
make -j$(nproc) all
make modules_install
make install

echo "Kernel build complete!"
