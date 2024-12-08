#!/bin/bash
set -e

# GhostOS + GhostC Build System for Pi Zero W
GHOST_VERSION="1.0.0"
GHOSTC_VERSION="1.0.0"

# Build environment
export LFS=/mnt/lfs
export LFS_TGT=arm-lfs-linux-gnueabihf
export PATH=/tools/bin:/bin:/usr/bin
export MAKEFLAGS="-j$(nproc)"
export LC_ALL=POSIX

# Package versions
BINUTILS_VERSION="2.37"
GCC_VERSION="11.2.0"
GLIBC_VERSION="2.34"
LINUX_VERSION="5.10.92"
BUSYBOX_VERSION="1.33.1"
OPENSSL_VERSION="1.1.1m"
LIBPCAP_VERSION="1.10.1"
TENSORFLOW_LITE="2.5.0"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

# Root check
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Please run as root${NC}"
    exit 1
fi

# Setup build directories
setup_build_env() {
    echo -e "${BLUE}Setting up build environment...${NC}"
    
    # Create LFS structure
    mkdir -pv $LFS
    mkdir -pv $LFS/{tools,sources}
    mkdir -pv $LFS/{bin,boot,dev,etc,home,lib,mnt,opt,proc,root,run,sbin,srv,sys,tmp,usr,var}
    mkdir -pv $LFS/usr/{bin,lib,sbin,include,share,src}
    mkdir -pv $LFS/var/{log,mail,spool,run}
    
    # Create symlinks
    ln -sfv usr/bin $LFS/bin
    ln -sfv usr/lib $LFS/lib
    ln -sfv usr/sbin $LFS/sbin
    ln -sfv bin usr/bin
    ln -sfv lib usr/lib
    ln -sfv sbin usr/sbin
    
    # Set permissions
    chmod -v 1777 $LFS/tmp $LFS/var/tmp
    chmod -v 0750 $LFS/root
    
    # Create GhostC directories
    mkdir -pv $LFS/usr/local/lib/ghostc
    mkdir -pv $LFS/usr/local/include/ghostc
    mkdir -pv $LFS/etc/ghost
}

# Download required packages
download_sources() {
    echo -e "${BLUE}Downloading source packages...${NC}"
    cd $LFS/sources
    
    # Core system
    wget -c https://ftp.gnu.org/gnu/binutils/binutils-${BINUTILS_VERSION}.tar.xz
    wget -c https://ftp.gnu.org/gnu/gcc/gcc-${GCC_VERSION}/gcc-${GCC_VERSION}.tar.xz
    wget -c https://ftp.gnu.org/gnu/glibc/glibc-${GLIBC_VERSION}.tar.xz
    wget -c https://cdn.kernel.org/pub/linux/kernel/v5.x/linux-${LINUX_VERSION}.tar.xz
    wget -c https://busybox.net/downloads/busybox-${BUSYBOX_VERSION}.tar.bz2
    wget -c https://www.openssl.org/source/openssl-${OPENSSL_VERSION}.tar.gz
    wget -c https://www.tcpdump.org/release/libpcap-${LIBPCAP_VERSION}.tar.gz
    
    # Extract all packages
    for f in *.tar.*; do
        tar xf $f
    done
}

# Build cross-toolchain
build_toolchain() {
    echo -e "${BLUE}Building cross-toolchain...${NC}"
    
    # Build Binutils (Pass 1)
    cd $LFS/sources/binutils-${BINUTILS_VERSION}
    mkdir -v build && cd build
    ../configure --prefix=/tools            \
                --with-sysroot=$LFS        \
                --target=$LFS_TGT          \
                --disable-nls              \
                --disable-werror           \
                --with-lib-path=/tools/lib
    make
    make install
    
    # Build GCC (Pass 1)
    cd $LFS/sources/gcc-${GCC_VERSION}
    mkdir -v build && cd build
    ../configure --prefix=/tools            \
                --with-sysroot=$LFS        \
                --target=$LFS_TGT          \
                --disable-nls              \
                --disable-shared           \
                --without-headers          \
                --with-newlib             \
                --disable-decimal-float    \
                --disable-threads         \
                --disable-libatomic       \
                --disable-libgomp         \
                --disable-libquadmath     \
                --disable-libssp          \
                --disable-libvtv          \
                --disable-multilib        \
                --enable-languages=c
    make
    make install
}

# Build GhostC
build_ghostc() {
    echo -e "${BLUE}Building GhostC...${NC}"
    
    cd $LFS/usr/src/ghostc
    
    # Build core library
    $LFS_TGT-gcc -c -fPIC src/*.c -I./include
    $LFS_TGT-gcc -shared -o libghostc.so *.o
    
    # Install GhostC
    cp libghostc.so $LFS/usr/local/lib/
    cp -r include/ghostc/* $LFS/usr/local/include/ghostc/
    
    # Build GhostC tools
    $LFS_TGT-gcc tools/ghostc-init.c -o $LFS/usr/local/bin/ghostc-init
    $LFS_TGT-gcc tools/ghostc-monitor.c -o $LFS/usr/local/bin/ghostc-monitor
    $LFS_TGT-gcc tools/ghostc-neural.c -o $LFS/usr/local/bin/ghostc-neural
    
    chmod +x $LFS/usr/local/bin/ghostc-*
}

# Configure system
configure_system() {
    echo -e "${BLUE}Configuring system...${NC}"
    
    # Create basic configuration files
    cat > $LFS/etc/ghost/config << EOF
# GhostOS Configuration
GHOST_VERSION="${GHOST_VERSION}"
GHOSTC_VERSION="${GHOSTC_VERSION}"

# System Settings
GHOST_SECURE_MODE=1
GHOST_STEALTH_MODE=1
GHOST_NEURAL_ENABLE=1

# Hardware Settings
GHOST_CPU_FREQ=1000
GHOST_GPU_MEM=16
GHOST_UART_ENABLE=1
GHOST_SPI_ENABLE=1
GHOST_I2C_ENABLE=1

# Network Settings
GHOST_NETWORK_STEALTH=1
GHOST_WIFI_MONITOR=1
EOF

    # Create boot configuration
    cat > $LFS/boot/config.txt << EOF
# GhostOS Boot Configuration
arm_64bit=0
kernel=kernel7.img
gpu_mem=16
dtoverlay=miniuart-bt
enable_uart=1

# CPU Settings
arm_freq=1000
over_voltage=0
force_turbo=0

# Hardware Settings
dtparam=spi=on
dtparam=i2c_arm=on
dtparam=i2c1=on
dtparam=i2c1_baudrate=400000

# Security Settings
disable_commandline_tags=1
EOF

    # Create init script
    cat > $LFS/etc/init.d/rcS << EOF
#!/bin/sh
/bin/mount -t proc none /proc
/bin/mount -t sysfs none /sys
/bin/mount -t devtmpfs none /dev
/bin/mount -t tmpfs none /tmp
/bin/mount -t tmpfs none /run

# Initialize GhostC
/usr/local/bin/ghostc-init

# Start system monitor
/usr/local/bin/ghostc-monitor &

# Start neural processing if enabled
if grep -q "GHOST_NEURAL_ENABLE=1" /etc/ghost/config; then
    /usr/local/bin/ghostc-neural &
fi

# Start shell
exec /bin/sh
EOF
    chmod +x $LFS/etc/init.d/rcS
}

# Build kernel
build_kernel() {
    echo -e "${BLUE}Building Linux kernel...${NC}"
    
    cd $LFS/sources/linux-${LINUX_VERSION}
    make ARCH=arm bcm2835_defconfig
    
    # Enable required features
    cat >> .config << EOF
CONFIG_GPIO_BCM2835=y
CONFIG_GPIO_SYSFS=y
CONFIG_SPI_BCM2835=y
CONFIG_I2C_BCM2835=y
CONFIG_CRYPTO_USER=y
CONFIG_CRYPTO_AES=y
CONFIG_CRYPTO_SHA256=y
CONFIG_NETFILTER=y
CONFIG_NETFILTER_ADVANCED=y
CONFIG_NF_CONNTRACK=y
CONFIG_NETFILTER_XT_TARGET_DROP=y
EOF
    
    make ARCH=arm CROSS_COMPILE=$LFS_TGT- -j$(nproc)
    make ARCH=arm CROSS_COMPILE=$LFS_TGT- INSTALL_MOD_PATH=$LFS modules_install
    cp arch/arm/boot/zImage $LFS/boot/kernel7.img
    cp arch/arm/boot/dts/bcm2835-rpi-zero-w.dtb $LFS/boot/
}

# Main build process
main() {
    echo -e "${GREEN}Starting GhostOS build process...${NC}"
    
    setup_build_env
    download_sources
    build_toolchain
    build_kernel
    build_ghostc
    configure_system
    
    echo -e "${GREEN}Build complete!${NC}"
    echo -e "${BLUE}System is ready for testing${NC}"
}

# Run build
main
