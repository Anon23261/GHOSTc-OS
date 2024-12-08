#!/bin/bash

set -e
set -x

# Mount points
DEVICE="/dev/sda"
MOUNT_BOOT="/tmp/ghostos-build/boot"
MOUNT_ROOT="/tmp/ghostos-build/root"
SOURCES="/tmp/ghostos-build/sources"

# Create mount points
mkdir -p $MOUNT_BOOT $MOUNT_ROOT $SOURCES

# Mount partitions
mount ${DEVICE}1 $MOUNT_BOOT
mount ${DEVICE}2 $MOUNT_ROOT

# Set up environment
export LFS=$MOUNT_ROOT
export LFS_TGT=arm-linux-gnueabihf
export PATH=/tools/bin:/bin:/usr/bin
export MAKEFLAGS="-j$(nproc)"
export ARCH=arm
export CROSS_COMPILE=$LFS_TGT-

# Pi Zero W specific flags
export CFLAGS="-O2 -march=armv6zk -mtune=arm1176jzf-s -mfpu=vfp -mfloat-abi=hard"
export CXXFLAGS="$CFLAGS"

# Download sources
cd $SOURCES
wget https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-6.6.4.tar.xz
wget https://ftp.gnu.org/gnu/binutils/binutils-2.40.tar.xz
wget https://ftp.gnu.org/gnu/gcc/gcc-13.2.0/gcc-13.2.0.tar.xz
wget https://ftp.gnu.org/gnu/glibc/glibc-2.38.tar.xz
wget https://busybox.net/downloads/busybox-1.36.1.tar.bz2

# Build cross-toolchain
cd $SOURCES

# 1. Binutils
tar xf binutils-2.40.tar.xz
cd binutils-2.40
mkdir build && cd build
../configure --prefix=/tools --target=$LFS_TGT --disable-nls --disable-werror
make -j$(nproc)
make install
cd ../..

# 2. GCC (Pass 1)
tar xf gcc-13.2.0.tar.xz
cd gcc-13.2.0
./contrib/download_prerequisites
mkdir build && cd build
../configure --prefix=/tools --target=$LFS_TGT --disable-nls --disable-shared \
    --disable-multilib --disable-threads --disable-libatomic \
    --disable-libgomp --disable-libquadmath --disable-libssp \
    --disable-libvtv --disable-libstdcxx --enable-languages=c,c++
make -j$(nproc)
make install
cd ../..

# 3. Linux Headers
tar xf linux-6.6.4.tar.xz
cd linux-6.6.4
make ARCH=arm INSTALL_HDR_PATH=/tools/$LFS_TGT headers_install
cd ..

# 4. Glibc
tar xf glibc-2.38.tar.xz
cd glibc-2.38
mkdir build && cd build
../configure --prefix=/tools/$LFS_TGT --build=$LFS_TGT \
    --host=$LFS_TGT --target=$LFS_TGT --with-headers=/tools/$LFS_TGT/include \
    libc_cv_forced_unwind=yes
make -j$(nproc)
make install
cd ../..

# 5. GCC (Pass 2)
cd gcc-13.2.0
rm -rf build
mkdir build && cd build
../configure --prefix=/tools --target=$LFS_TGT --disable-nls \
    --enable-languages=c,c++ --enable-shared --disable-multilib
make -j$(nproc)
make install
cd ../..

# Build kernel
cd linux-6.6.4
make ARCH=arm bcmrpi_defconfig
make ARCH=arm CROSS_COMPILE=$CROSS_COMPILE -j$(nproc) zImage modules dtbs
make ARCH=arm CROSS_COMPILE=$CROSS_COMPILE INSTALL_MOD_PATH=$LFS modules_install
cp arch/arm/boot/zImage $MOUNT_BOOT/kernel7.img
cp arch/arm/boot/dts/bcm*.dtb $MOUNT_BOOT/
cp arch/arm/boot/dts/overlays/*.dtb* $MOUNT_BOOT/overlays/
cp arch/arm/boot/dts/overlays/README $MOUNT_BOOT/overlays/
cd ..

# Build BusyBox
tar xf busybox-1.36.1.tar.bz2
cd busybox-1.36.1
make ARCH=arm CROSS_COMPILE=$CROSS_COMPILE defconfig
sed -i 's/# CONFIG_STATIC is not set/CONFIG_STATIC=y/' .config
make ARCH=arm CROSS_COMPILE=$CROSS_COMPILE -j$(nproc)
make ARCH=arm CROSS_COMPILE=$CROSS_COMPILE CONFIG_PREFIX=$LFS install
cd ..

# Build GhostC
cd /media/ghost/12B4-F9B2/Software/ghostOS/src/ghost
mkdir -p build && cd build
cmake -DCMAKE_TOOLCHAIN_FILE=../cmake/toolchain-arm-none-linux-gnueabihf.cmake ..
make -j$(nproc)
make install DESTDIR=$LFS

# Create basic system configuration
mkdir -p $LFS/etc
cat > $LFS/etc/inittab << "EOF"
::sysinit:/etc/init.d/rcS
::respawn:-/bin/sh
tty2::askfirst:-/bin/sh
::ctrlaltdel:/sbin/reboot
::shutdown:/sbin/swapoff -a
::shutdown:/bin/umount -a -r
::restart:/sbin/init
EOF

mkdir -p $LFS/etc/init.d
cat > $LFS/etc/init.d/rcS << "EOF"
#!/bin/sh
mount -t proc proc /proc
mount -t sysfs sysfs /sys
mount -t devtmpfs devtmpfs /dev
mkdir -p /dev/pts /dev/shm
mount -t devpts devpts /dev/pts
mount -t tmpfs tmpfs /dev/shm
mount -t tmpfs tmpfs /tmp
mount -t tmpfs tmpfs /run
EOF
chmod +x $LFS/etc/init.d/rcS

# Set up networking
mkdir -p $LFS/etc/network
cat > $LFS/etc/network/interfaces << "EOF"
auto lo
iface lo inet loopback

allow-hotplug wlan0
iface wlan0 inet dhcp
    wpa-conf /etc/wpa_supplicant/wpa_supplicant.conf
EOF

# Clean up
cd /
umount $MOUNT_BOOT
umount $MOUNT_ROOT

echo "GhostOS built and installed successfully!"
