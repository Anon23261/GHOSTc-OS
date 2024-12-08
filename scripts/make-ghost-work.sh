#!/bin/bash
set -e
set -x

# Device and mount points
DEVICE="/dev/sda"
WORKDIR="/tmp/ghost-build"
BOOT="${WORKDIR}/boot"
ROOT="${WORKDIR}/root"

# Clean and create work directory
rm -rf "$WORKDIR"
mkdir -p "$BOOT" "$ROOT"

# Mount partitions
mount ${DEVICE}1 "$BOOT"
mount ${DEVICE}2 "$ROOT"

# Set up basic root filesystem
mkdir -p "${ROOT}"/{bin,boot,dev,etc,home,lib,media,mnt,opt,proc,root,run,sbin,srv,sys,tmp,usr/local/{bin,lib,include},var}
chmod 1777 "${ROOT}/tmp"
chmod 700 "${ROOT}/root"

# Copy GhostC files
cp -r /media/ghost/12B4-F9B2/Software/ghostOS/src/ghost/src/ghostc "${ROOT}/usr/local/lib/"
cp -r /media/ghost/12B4-F9B2/Software/ghostOS/src/ghost/include/ghostc "${ROOT}/usr/local/include/"

# Create basic system config
cat > "${ROOT}/etc/inittab" << "EOF"
::sysinit:/etc/init.d/rcS
::respawn:-/bin/sh
tty2::askfirst:-/bin/sh
::ctrlaltdel:/sbin/reboot
::shutdown:/sbin/swapoff -a
::shutdown:/bin/umount -a -r
::restart:/sbin/init
EOF

# Create startup script
mkdir -p "${ROOT}/etc/init.d"
cat > "${ROOT}/etc/init.d/rcS" << "EOF"
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
chmod +x "${ROOT}/etc/init.d/rcS"

# Set up boot config
cat > "${BOOT}/config.txt" << "EOF"
# GhostOS config for Pi Zero W
arm_64bit=0
kernel=kernel7.img
gpu_mem=16
dtoverlay=miniuart-bt
enable_uart=1
EOF

# Set up cmdline
echo "console=serial0,115200 console=tty1 root=/dev/mmcblk0p2 rootfstype=ext4 elevator=deadline fsck.repair=yes rootwait quiet" > "${BOOT}/cmdline.txt"

# Download Pi firmware if not exists
cd "${WORKDIR}"
if [ ! -f bootcode.bin ]; then
    wget https://github.com/raspberrypi/firmware/raw/master/boot/bootcode.bin
    wget https://github.com/raspberrypi/firmware/raw/master/boot/start.elf
    wget https://github.com/raspberrypi/firmware/raw/master/boot/fixup.dat
fi

# Copy firmware files
cp bootcode.bin start.elf fixup.dat "${BOOT}/"

# Set up GhostC config
mkdir -p "${ROOT}/etc/ghost"
cat > "${ROOT}/etc/ghost/config" << "EOF"
GHOST_NEURAL_ENABLE=1
GHOST_SECURE_MODE=1
GHOST_STEALTH_MODE=1
GHOST_GPIO_ENABLE=1
EOF

# Create first boot script
cat > "${ROOT}/root/first_boot.sh" << "EOF"
#!/bin/sh
# Initialize GhostC
/usr/local/lib/ghostc/ghostc-init --setup
# Enable stealth mode
/usr/local/lib/ghostc/ghostc-stealth --enable
EOF
chmod +x "${ROOT}/root/first_boot.sh"

# Clean up
sync
umount "$BOOT"
umount "$ROOT"

echo "GhostOS is ready! Insert the SD card into your Pi Zero W and power on."
