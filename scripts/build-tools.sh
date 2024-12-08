#!/bin/bash

set -e

TOOLS_DIR="/media/ghost/12B4-F9B2/Software/ghostOS/toolchain"
BUILD_DIR="/media/ghost/12B4-F9B2/Software/ghostOS/build/tools"
TARGET="x86_64-ghostos-linux-gnu"

# Create directories
mkdir -p ${TOOLS_DIR}
mkdir -p ${BUILD_DIR}

# Build essential development tools
build_binutils() {
    cd ${BUILD_DIR}
    wget https://ftp.gnu.org/gnu/binutils/binutils-2.40.tar.xz
    tar xf binutils-2.40.tar.xz
    mkdir build-binutils
    cd build-binutils
    ../binutils-2.40/configure --prefix=${TOOLS_DIR} \
        --target=${TARGET} \
        --with-sysroot=${TOOLS_DIR}/${TARGET} \
        --disable-nls \
        --disable-werror
    make -j$(nproc)
    make install
}

build_gcc() {
    cd ${BUILD_DIR}
    wget https://ftp.gnu.org/gnu/gcc/gcc-13.2.0/gcc-13.2.0.tar.xz
    tar xf gcc-13.2.0.tar.xz
    mkdir build-gcc
    cd build-gcc
    ../gcc-13.2.0/configure --prefix=${TOOLS_DIR} \
        --target=${TARGET} \
        --with-sysroot=${TOOLS_DIR}/${TARGET} \
        --disable-nls \
        --enable-languages=c,c++ \
        --without-headers
    make -j$(nproc) all-gcc
    make install-gcc
}

build_gdb() {
    cd ${BUILD_DIR}
    wget https://ftp.gnu.org/gnu/gdb/gdb-13.2.tar.xz
    tar xf gdb-13.2.tar.xz
    mkdir build-gdb
    cd build-gdb
    ../gdb-13.2/configure --prefix=${TOOLS_DIR} \
        --target=${TARGET}
    make -j$(nproc)
    make install
}

# Build the tools
echo "Building binutils..."
build_binutils

echo "Building GCC..."
build_gcc

echo "Building GDB..."
build_gdb

echo "Development tools built successfully!"
