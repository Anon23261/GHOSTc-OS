#!/bin/bash

set -e
set -x

# LFS system settings for Pi Zero W (ARMv6)
export LFS=/mnt/lfs
export LFS_TGT=arm-linux-gnueabihf
export PATH=/tools/bin:/bin:/usr/bin
export MAKEFLAGS="-j$(nproc)"
export ARCH=arm
export CROSS_COMPILE=$LFS_TGT-

# Core package versions
BINUTILS_VERSION="2.40"
GCC_VERSION="13.2.0"
LINUX_VERSION="6.6.4"
BUSYBOX_VERSION="1.36.1"
RASPBERRYPI_FIRMWARE="master"  # Use master for latest firmware
GMP_VERSION="6.2.1"
MPFR_VERSION="4.2.1"
MPC_VERSION="1.3.1"
GLIBC_VERSION="2.38"

# Source URLs
BINUTILS_URL="https://ftp.gnu.org/gnu/binutils/binutils-${BINUTILS_VERSION}.tar.xz"
GCC_URL="https://ftp.gnu.org/gnu/gcc/gcc-${GCC_VERSION}/gcc-${GCC_VERSION}.tar.xz"
LINUX_URL="https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-${LINUX_VERSION}.tar.xz"
BUSYBOX_URL="https://busybox.net/downloads/busybox-${BUSYBOX_VERSION}.tar.bz2"
RPI_FIRMWARE_URL="https://github.com/raspberrypi/firmware/archive/${RASPBERRYPI_FIRMWARE}.tar.gz"
GMP_URL="https://ftp.gnu.org/gnu/gmp/gmp-${GMP_VERSION}.tar.xz"
MPFR_URL="https://ftp.gnu.org/gnu/mpfr/mpfr-${MPFR_VERSION}.tar.xz"
MPC_URL="https://ftp.gnu.org/gnu/mpc/mpc-${MPC_VERSION}.tar.gz"
GLIBC_URL="https://ftp.gnu.org/gnu/glibc/glibc-${GLIBC_VERSION}.tar.xz"

# Hardware-specific settings
PI_ZERO_CFLAGS="-O2 -march=armv6zk -mtune=arm1176jzf-s -mfpu=vfp -mfloat-abi=hard"
PI_ZERO_CXXFLAGS="$PI_ZERO_CFLAGS"

check_requirements() {
    echo "Checking build requirements..."
    
    # Required tools
    REQUIRED_TOOLS="wget gcc g++ make bison flex gawk tar gzip xz bzip2 patch"
    
    # Check each tool
    for tool in $REQUIRED_TOOLS; do
        if ! command -v $tool >/dev/null 2>&1; then
            echo "Error: Required tool '$tool' is not installed"
            echo "Please install the missing tool and try again"
            exit 1
        fi
    done
    
    # Check if running as root or with sudo
    if [ "$EUID" -ne 0 ] && [ -z "$SUDO_USER" ]; then
        echo "Error: This script must be run as root or with sudo"
        exit 1
    fi
    
    echo "All requirements satisfied"
}

setup_tools() {
    echo "Setting up tools directory..."
    if [ -e /tools ]; then
        echo "Removing existing /tools directory..."
        sudo rm -rf /tools
    fi
    if [ -e /mnt/lfs ]; then
        echo "Removing existing /mnt/lfs directory..."
        sudo rm -rf /mnt/lfs
    fi
    sudo mkdir -pv /mnt/lfs
    sudo mkdir -pv /tools
    # Create tools directory in /mnt/lfs and symlink it to /
    sudo ln -sfnv /mnt/lfs/tools /tools
    sudo chmod -R 777 /tools /mnt/lfs
}

create_filesystem() {
    echo "Creating minimal filesystem..."
    for dir in bin boot dev etc lib proc sys tmp usr/bin usr/lib usr/sbin var/log; do
        mkdir -pv $LFS/$dir
    done
    
    # Create essential device nodes
    sudo mknod -m 600 $LFS/dev/console c 5 1
    sudo mknod -m 666 $LFS/dev/null c 1 3
}

download_sources() {
    echo "Downloading source packages..."
    mkdir -pv $LFS/sources
    cd $LFS/sources
    
    # Download all sources
    wget $BINUTILS_URL
    wget $GCC_URL
    wget $LINUX_URL
    wget $BUSYBOX_URL
    wget $RPI_FIRMWARE_URL -O firmware.tar.gz
    wget $GMP_URL
    wget $MPFR_URL
    wget $MPC_URL
    wget $GLIBC_URL
    
    # Extract GCC dependencies
    tar xf gmp-${GMP_VERSION}.tar.xz
    tar xf mpfr-${MPFR_VERSION}.tar.xz
    tar xf mpc-${MPC_VERSION}.tar.gz
    
    # Extract GCC and link dependencies
    tar xf gcc-${GCC_VERSION}.tar.xz
    cd gcc-${GCC_VERSION}
    ln -sf ../gmp-${GMP_VERSION} gmp
    ln -sf ../mpfr-${MPFR_VERSION} mpfr
    ln -sf ../mpc-${MPC_VERSION} mpc
    cd ..
    
    # Extract other packages
    tar xf binutils-${BINUTILS_VERSION}.tar.xz
    tar xf linux-${LINUX_VERSION}.tar.xz
    tar xf busybox-${BUSYBOX_VERSION}.tar.bz2
    tar xf glibc-${GLIBC_VERSION}.tar.xz
    tar xf firmware.tar.gz
}

build_linux_headers() {
    echo "Installing Linux headers..."
    cd $LFS/sources/linux-${LINUX_VERSION}
    make ARCH=arm CROSS_COMPILE=$LFS_TGT- mrproper
    make ARCH=arm CROSS_COMPILE=$LFS_TGT- headers
    find usr/include -type f ! -name '*.h' -delete
    mkdir -pv $LFS/tools/include
    cp -rv usr/include/* $LFS/tools/include/
    cp -rv include/* $LFS/tools/include/
    
    # Create version.h if it doesn't exist
    if [ ! -f $LFS/tools/include/linux/version.h ]; then
        echo "#define LINUX_VERSION_CODE $(($LINUX_VERSION))" > $LFS/tools/include/linux/version.h
        echo "#define KERNEL_VERSION(a,b,c) (((a) << 16) + ((b) << 8) + (c))" >> $LFS/tools/include/linux/version.h
    fi
}

build_cross_binutils() {
    echo "Building cross binutils..."
    cd $LFS/sources
    rm -rf binutils-build
    mkdir -v binutils-build
    cd binutils-build
    
    ../binutils-${BINUTILS_VERSION}/configure \
        --prefix=/tools \
        --with-sysroot=$LFS \
        --target=$LFS_TGT \
        --disable-nls \
        --disable-werror \
        --with-arch=armv6 \
        --with-fpu=vfp \
        --with-float-abi=hard
        
    make
    make install
}

build_cross_gcc() {
    echo "Building cross GCC..."
    cd $LFS/sources
    rm -rf gcc-build
    mkdir -v gcc-build
    cd gcc-build
    
    ../gcc-${GCC_VERSION}/configure \
        --prefix=/tools \
        --target=$LFS_TGT \
        --with-arch=armv6 \
        --with-fpu=vfp \
        --with-float-abi=hard \
        --enable-languages=c,c++ \
        --disable-multilib \
        --disable-nls \
        --disable-shared \
        --disable-threads \
        --disable-libatomic \
        --disable-libgomp \
        --disable-libquadmath \
        --disable-libssp \
        --disable-libvtv \
        --with-gmp=/tools \
        --with-mpfr=/tools \
        --with-mpc=/tools
        
    make all-gcc all-target-libgcc all-target-libstdc++-v3
    make install-gcc install-target-libgcc install-target-libstdc++-v3
}

build_glibc() {
    echo "Building glibc..."
    cd $LFS/sources
    rm -rf glibc-build
    mkdir -v glibc-build
    cd glibc-build
    
    ../glibc-${GLIBC_VERSION}/configure \
        --prefix=/tools \
        --host=$LFS_TGT \
        --build=$(../glibc-${GLIBC_VERSION}/scripts/config.guess) \
        --enable-kernel=3.2 \
        --with-headers=/tools/include \
        libc_cv_forced_unwind=yes \
        libc_cv_c_cleanup=yes
        
    make
    make install
}

build_kernel() {
    echo "Building Linux kernel for Pi Zero W..."
    cd $LFS/sources/linux-${LINUX_VERSION}
    
    # Check if kernel config exists
    if [ ! -f $LFS/../config/kernel.config ]; then
        echo "Error: kernel.config not found in $LFS/../config/"
        echo "Please ensure the kernel config file exists before building"
        exit 1
    fi
    
    # Use our optimized kernel config
    cp $LFS/../config/kernel.config .config
    
    # Build kernel
    make ARCH=arm CROSS_COMPILE=$LFS_TGT- oldconfig
    make ARCH=arm CROSS_COMPILE=$LFS_TGT- zImage modules dtbs
    
    # Install kernel
    make ARCH=arm CROSS_COMPILE=$LFS_TGT- INSTALL_MOD_PATH=$LFS modules_install
    cp arch/arm/boot/zImage $LFS/boot/kernel.img
    cp arch/arm/boot/dts/bcm2835-rpi-zero-w.dtb $LFS/boot/
}

build_busybox() {
    echo "Building BusyBox..."
    cd $LFS/sources/busybox-${BUSYBOX_VERSION}
    
    # Configure for static build
    make ARCH=arm CROSS_COMPILE=$LFS_TGT- defconfig
    sed -i 's/# CONFIG_STATIC is not set/CONFIG_STATIC=y/' .config
    
    # Build and install
    make ARCH=arm CROSS_COMPILE=$LFS_TGT- \
        CONFIG_PREFIX=$LFS install
}

setup_ghost() {
    echo "Setting up Ghost system..."
    cd $LFS/sources
    
    # Check if Ghost directories exist
    if [ ! -d ghost/runtime ] || [ ! -d ghost/services ]; then
        echo "Error: Ghost runtime or services directory not found"
        echo "Please ensure the Ghost source code is properly set up"
        exit 1
    fi
    
    # Build Ghost runtime
    cd ghost/runtime
    make ARCH=arm CROSS_COMPILE=$LFS_TGT- \
        CFLAGS="$PI_ZERO_CFLAGS" \
        CXXFLAGS="$PI_ZERO_CXXFLAGS"
    make ARCH=arm CROSS_COMPILE=$LFS_TGT- install
    
    # Build Ghost core services
    cd ../services
    make ARCH=arm CROSS_COMPILE=$LFS_TGT- \
        CFLAGS="$PI_ZERO_CFLAGS" \
        CXXFLAGS="$PI_ZERO_CXXFLAGS"
    make ARCH=arm CROSS_COMPILE=$LFS_TGT- install
}

configure_system() {
    echo "Configuring system..."
    
    # Create fstab
    cat > $LFS/etc/fstab << "EOF"
/dev/mmcblk0p1  /boot  vfat  defaults  0  0
/dev/mmcblk0p2  /      ext4  defaults  0  1
proc            /proc  proc  defaults  0  0
tmpfs           /tmp   tmpfs defaults  0  0
EOF

    # Configure network
    mkdir -p $LFS/etc/network
    cat > $LFS/etc/network/interfaces << "EOF"
auto lo
iface lo inet loopback

allow-hotplug wlan0
iface wlan0 inet dhcp
    wpa-conf /etc/wpa_supplicant/wpa_supplicant.conf
EOF

    # Create minimal init
    cat > $LFS/sbin/init << "EOF"
#!/bin/sh
mount -t proc proc /proc
mount -t sysfs sysfs /sys
mount -t tmpfs tmpfs /tmp

# Setup network
ifconfig lo up
/sbin/wpa_supplicant -B -i wlan0 -c /etc/wpa_supplicant/wpa_supplicant.conf
udhcpc -i wlan0

# Start Ghost
/bin/ghost-init

exec /bin/sh
EOF
    chmod +x $LFS/sbin/init
}

cleanup() {
    echo "Cleaning up build artifacts..."
    
    # Remove build directories
    cd $LFS/sources
    rm -rf binutils-build gcc-build glibc-build
    
    # Remove extracted source directories to save space
    rm -rf binutils-${BINUTILS_VERSION}
    rm -rf gcc-${GCC_VERSION}
    rm -rf glibc-${GLIBC_VERSION}
    rm -rf linux-${LINUX_VERSION}
    rm -rf busybox-${BUSYBOX_VERSION}
    rm -rf gmp-${GMP_VERSION}
    rm -rf mpfr-${MPFR_VERSION}
    rm -rf mpc-${MPC_VERSION}
    rm -rf firmware-${RASPBERRYPI_FIRMWARE}
    
    # Remove downloaded archives
    rm -f *.tar.* firmware.tar.gz
    
    echo "Cleanup complete"
}

main() {
    echo "Building GhostOS for Pi Zero W..."
    check_requirements
    setup_tools
    create_filesystem
    download_sources
    build_linux_headers
    build_cross_binutils
    build_cross_gcc
    build_glibc
    build_kernel
    build_busybox
    setup_ghost
    configure_system
    cleanup
    echo "GhostOS build complete!"
}

main "$@"
