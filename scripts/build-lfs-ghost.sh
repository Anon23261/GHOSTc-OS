#!/bin/bash
set -e

# LFS build script for GhostOS
# This builds a complete Linux From Scratch system optimized for Pi Zero W

# Environment setup
export LFS=/mnt/lfs
export LFS_TGT=$(uname -m)-lfs-linux-gnu
export PATH=/tools/bin:/bin:/usr/bin
export MAKEFLAGS="-j$(nproc)"
export LC_ALL=POSIX

# Package versions
BINUTILS_VERSION="2.37"
GCC_VERSION="11.2.0"
GLIBC_VERSION="2.34"
LINUX_VERSION="5.10.92"
BUSYBOX_VERSION="1.33.1"

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

# Create LFS directory structure
setup_directories() {
    echo -e "${BLUE}Creating LFS directory structure...${NC}"
    mkdir -pv $LFS
    mkdir -pv $LFS/tools
    mkdir -pv $LFS/sources
    mkdir -pv $LFS/{bin,boot,dev,etc,home,lib,mnt,opt,proc,root,run,sbin,srv,sys,tmp,usr,var}
    
    # Create symlinks
    ln -sv usr/bin $LFS/bin
    ln -sv usr/lib $LFS/lib
    ln -sv usr/sbin $LFS/sbin
    ln -sv bin usr/bin
    ln -sv lib usr/lib
    ln -sv sbin usr/sbin
    
    # Create tools directory
    mkdir -pv $LFS/tools
    
    # Set permissions
    chmod -v 1777 $LFS/tmp
    chmod -v 0750 $LFS/root
    chmod -v 1777 $LFS/var/tmp
}

# Download required packages
download_sources() {
    echo -e "${BLUE}Downloading source packages...${NC}"
    cd $LFS/sources
    
    # Download core packages
    wget https://ftp.gnu.org/gnu/binutils/binutils-${BINUTILS_VERSION}.tar.xz
    wget https://ftp.gnu.org/gnu/gcc/gcc-${GCC_VERSION}/gcc-${GCC_VERSION}.tar.xz
    wget https://ftp.gnu.org/gnu/glibc/glibc-${GLIBC_VERSION}.tar.xz
    wget https://cdn.kernel.org/pub/linux/kernel/v5.x/linux-${LINUX_VERSION}.tar.xz
    wget https://busybox.net/downloads/busybox-${BUSYBOX_VERSION}.tar.bz2
    
    # Extract packages
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
                --disable-werror
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

# Build basic system
build_basic_system() {
    echo -e "${BLUE}Building basic system...${NC}"
    
    # Build Linux headers
    cd $LFS/sources/linux-${LINUX_VERSION}
    make mrproper
    make ARCH=arm INSTALL_HDR_PATH=$LFS/usr headers_install
    
    # Build Glibc
    cd $LFS/sources/glibc-${GLIBC_VERSION}
    mkdir -v build && cd build
    ../configure --prefix=/usr                \
                --host=$LFS_TGT              \
                --build=$(../scripts/config.guess) \
                --enable-kernel=3.2          \
                --with-headers=$LFS/usr/include
    make
    make DESTDIR=$LFS install
    
    # Build BusyBox
    cd $LFS/sources/busybox-${BUSYBOX_VERSION}
    make defconfig
    sed -i 's/^.*CONFIG_STATIC.*$/CONFIG_STATIC=y/' .config
    make ARCH=arm CROSS_COMPILE=$LFS_TGT-
    make ARCH=arm CROSS_COMPILE=$LFS_TGT- CONFIG_PREFIX=$LFS install
}

# Configure system
configure_system() {
    echo -e "${BLUE}Configuring system...${NC}"
    
    # Create essential files and symlinks
    ln -sv /proc/self/mounts $LFS/etc/mtab
    
    # Create passwd file
    cat > $LFS/etc/passwd << "EOF"
root:x:0:0:root:/root:/bin/sh
EOF
    
    # Create group file
    cat > $LFS/etc/group << "EOF"
root:x:0:
bin:x:1:
sys:x:2:
kmem:x:3:
tty:x:4:
daemon:x:6:
disk:x:8:
dialout:x:10:
video:x:12:
utmp:x:13:
usb:x:14:
EOF
    
    # Create init script
    cat > $LFS/etc/init.d/rcS << "EOF"
#!/bin/sh
/bin/mount -t proc none /proc
/bin/mount -t sysfs none /sys
/bin/mount -t devtmpfs none /dev
/bin/mount -t tmpfs none /tmp
/bin/mount -t tmpfs none /run

# Start system initialization
/usr/local/lib/ghostc/ghostc-init

# Start shell
exec /bin/sh
EOF
    chmod +x $LFS/etc/init.d/rcS
}

# Main build process
main() {
    echo -e "${GREEN}Starting GhostOS LFS build...${NC}"
    
    setup_directories
    download_sources
    build_toolchain
    build_basic_system
    configure_system
    
    echo -e "${GREEN}LFS build complete!${NC}"
    echo -e "${BLUE}The system is ready for testing in $LFS${NC}"
}

# Run build
main
