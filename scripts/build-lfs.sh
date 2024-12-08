#!/bin/bash

# GhostOS LFS build script
set -e

# Environment setup
export LFS=/mnt/lfs
export LFS_TGT=$(uname -m)-lfs-linux-gnu
export PATH=/tools/bin:/bin:/usr/bin

# Version definitions
BINUTILS_VERSION="2.40"
GCC_VERSION="12.2.0"
GLIBC_VERSION="2.37"
LINUX_VERSION="6.1.11"

# Create LFS filesystem structure
mkdir -pv $LFS
mkdir -pv $LFS/sources
mkdir -pv $LFS/tools
mkdir -pv $LFS/boot
mkdir -pv $LFS/etc
mkdir -pv $LFS/bin
mkdir -pv $LFS/lib
mkdir -pv $LFS/sbin
mkdir -pv $LFS/usr
mkdir -pv $LFS/var

# Download core packages
cd $LFS/sources
wget https://ftp.gnu.org/gnu/binutils/binutils-$BINUTILS_VERSION.tar.xz
wget https://ftp.gnu.org/gnu/gcc/gcc-$GCC_VERSION/gcc-$GCC_VERSION.tar.xz
wget https://ftp.gnu.org/gnu/glibc/glibc-$GLIBC_VERSION.tar.xz
wget https://www.kernel.org/pub/linux/kernel/v6.x/linux-$LINUX_VERSION.tar.xz

# Build cross-toolchain
echo "Building cross-toolchain..."

# 1. Binutils (Pass 1)
cd $LFS/sources
tar xf binutils-$BINUTILS_VERSION.tar.xz
cd binutils-$BINUTILS_VERSION
mkdir -v build
cd build
../configure --prefix=$LFS/tools \
    --with-sysroot=$LFS \
    --target=$LFS_TGT \
    --disable-nls \
    --enable-gprofng=no \
    --disable-werror
make
make install

# 2. GCC (Pass 1)
cd $LFS/sources
tar xf gcc-$GCC_VERSION.tar.xz
cd gcc-$GCC_VERSION
mkdir -v build
cd build
../configure --target=$LFS_TGT \
    --prefix=$LFS/tools \
    --with-glibc-version=2.37 \
    --with-sysroot=$LFS \
    --with-newlib \
    --without-headers \
    --enable-default-pie \
    --enable-default-ssp \
    --disable-nls \
    --disable-shared \
    --disable-multilib \
    --disable-threads \
    --disable-libatomic \
    --disable-libgomp \
    --disable-libquadmath \
    --disable-libssp \
    --disable-libvtv \
    --disable-libstdcxx \
    --enable-languages=c,c++
make
make install

# Build basic system
echo "Building basic system..."

# 1. Linux API Headers
cd $LFS/sources
tar xf linux-$LINUX_VERSION.tar.xz
cd linux-$LINUX_VERSION
make mrproper
make headers
find usr/include -type f ! -name '*.h' -delete
cp -rv usr/include $LFS/usr

# 2. Glibc
cd $LFS/sources
tar xf glibc-$GLIBC_VERSION.tar.xz
cd glibc-$GLIBC_VERSION
mkdir -v build
cd build
../configure --prefix=/usr \
    --host=$LFS_TGT \
    --build=$(../scripts/config.guess) \
    --enable-kernel=3.2 \
    --with-headers=$LFS/usr/include
make
make DESTDIR=$LFS install

# Install development tools
echo "Installing development tools..."

# Create package list for development tools
cat > $LFS/etc/development-packages.txt << "EOF"
gcc
g++
make
cmake
git
python3
python3-pip
rust
golang
nodejs
vim
neovim
tmux
gdb
valgrind
docker
EOF

# Build Ghost AI system
echo "Building Ghost AI system..."

# Create Ghost AI directory structure
mkdir -pv $LFS/opt/ghost
mkdir -pv $LFS/opt/ghost/bin
mkdir -pv $LFS/opt/ghost/lib
mkdir -pv $LFS/opt/ghost/share
mkdir -pv $LFS/opt/ghost/include

# Copy Ghost AI source
cp -rv $LFS/sources/ghostOS/src/ghost/* $LFS/opt/ghost/

# Build Ghost AI
cd $LFS/opt/ghost
mkdir build
cd build
cmake ..
make -j$(nproc)
make install

echo "LFS build complete!"
