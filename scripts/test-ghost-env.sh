#!/bin/bash
set -e

# Configuration
WORKDIR="/media/ghost/12B4-F9B2/Software/ghostOS/test-env"
IMAGE_SIZE="2G"
QEMU_IMAGE="${WORKDIR}/ghost-test.img"

# Create test environment
setup_test_env() {
    echo "Setting up test environment..."
    mkdir -p "${WORKDIR}"
    
    # Create test image
    qemu-img create -f raw "${QEMU_IMAGE}" "${IMAGE_SIZE}"
    
    # Format the image
    parted "${QEMU_IMAGE}" --script mklabel msdos
    parted "${QEMU_IMAGE}" --script mkpart primary fat32 1MiB 256MiB
    parted "${QEMU_IMAGE}" --script mkpart primary ext4 256MiB 100%
    
    # Set up loop device
    LOOP_DEVICE=$(sudo losetup -fP --show "${QEMU_IMAGE}")
    
    # Format partitions
    sudo mkfs.vfat -F 32 "${LOOP_DEVICE}p1"
    sudo mkfs.ext4 "${LOOP_DEVICE}p2"
    
    # Mount partitions
    mkdir -p "${WORKDIR}/boot" "${WORKDIR}/root"
    sudo mount "${LOOP_DEVICE}p1" "${WORKDIR}/boot"
    sudo mount "${LOOP_DEVICE}p2" "${WORKDIR}/root"
    
    echo "Test environment ready at ${WORKDIR}"
    echo "Loop device: ${LOOP_DEVICE}"
}

# Install GhostOS to test environment
install_ghost() {
    echo "Installing GhostOS to test environment..."
    
    # Set up basic root filesystem
    sudo mkdir -p "${WORKDIR}/root"/{bin,boot,dev,etc,home,lib,media,mnt,opt,proc,root,run,sbin,srv,sys,tmp,usr/local/{bin,lib,include},var}
    sudo chmod 1777 "${WORKDIR}/root/tmp"
    sudo chmod 700 "${WORKDIR}/root/root"
    
    # Copy GhostC files
    sudo cp -r ../src/ghost/src/ghostc "${WORKDIR}/root/usr/local/lib/"
    sudo cp -r ../src/ghost/include/ghostc "${WORKDIR}/root/usr/local/include/"
    
    # Set up boot configuration
    cat > "${WORKDIR}/boot/config.txt" << "EOF"
# GhostOS Test Config (Pi Zero W simulation)
arm_64bit=0
kernel=kernel7.img
gpu_mem=16
dtoverlay=miniuart-bt
enable_uart=1
EOF
    
    # Create basic system configuration
    sudo tee "${WORKDIR}/root/etc/inittab" > /dev/null << "EOF"
::sysinit:/etc/init.d/rcS
::respawn:-/bin/sh
tty2::askfirst:-/bin/sh
::ctrlaltdel:/sbin/reboot
::shutdown:/sbin/swapoff -a
::shutdown:/bin/umount -a -r
::restart:/sbin/init
EOF
    
    # Create startup script
    sudo mkdir -p "${WORKDIR}/root/etc/init.d"
    sudo tee "${WORKDIR}/root/etc/init.d/rcS" > /dev/null << "EOF"
#!/bin/sh
mount -t proc proc /proc
mount -t sysfs sysfs /sys
mount -t devtmpfs devtmpfs /dev
mkdir -p /dev/pts /dev/shm
mount -t devpts devpts /dev/pts
mount -t tmpfs tmpfs /dev/shm
mount -t tmpfs tmpfs /tmp
mount -t tmpfs tmpfs /run

# Start GhostC
/usr/local/lib/ghostc/ghostc-init
EOF
    sudo chmod +x "${WORKDIR}/root/etc/init.d/rcS"
    
    echo "GhostOS installation complete"
}

# Start QEMU test environment
start_test() {
    echo "Starting QEMU test environment..."
    qemu-system-arm \
        -M versatilepb \
        -cpu arm1176 \
        -m 256 \
        -drive file="${QEMU_IMAGE}",format=raw \
        -net nic \
        -net user \
        -nographic
}

# Cleanup function
cleanup() {
    echo "Cleaning up..."
    sudo umount "${WORKDIR}/boot" 2>/dev/null || true
    sudo umount "${WORKDIR}/root" 2>/dev/null || true
    sudo losetup -d "${LOOP_DEVICE}" 2>/dev/null || true
}

# Main execution
case "$1" in
    setup)
        setup_test_env
        install_ghost
        ;;
    start)
        start_test
        ;;
    cleanup)
        cleanup
        ;;
    *)
        echo "Usage: $0 {setup|start|cleanup}"
        echo "  setup   - Create and prepare test environment"
        echo "  start   - Start QEMU test environment"
        echo "  cleanup - Clean up mounts and loop devices"
        exit 1
        ;;
esac

exit 0
