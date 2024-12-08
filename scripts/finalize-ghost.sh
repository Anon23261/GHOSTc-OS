#!/bin/bash

set -e
set -x

# Mount points
DEVICE="/dev/sda"
MOUNT_BOOT="/tmp/ghostos-build/boot"
MOUNT_ROOT="/tmp/ghostos-build/root"

# Create mount points
mkdir -p $MOUNT_BOOT $MOUNT_ROOT

# Mount partitions
mount ${DEVICE}1 $MOUNT_BOOT
mount ${DEVICE}2 $MOUNT_ROOT

# Set up GhostC environment
mkdir -p $MOUNT_ROOT/etc/ghost
cat > $MOUNT_ROOT/etc/ghost/config << EOF
# GhostC Configuration
GHOST_NEURAL_THREADS=4
GHOST_MEMORY_LIMIT=256M
GHOST_SECURE_MODE=1
GHOST_STEALTH_MODE=1
GHOST_GPIO_ACCESS=1
GHOST_UART_SPEED=115200
EOF

# Set up network stealth mode
cat > $MOUNT_ROOT/etc/ghost/network.conf << EOF
# Network stealth configuration
GHOST_NET_RANDOMIZE_MAC=1
GHOST_NET_HIDE_HOSTNAME=1
GHOST_NET_ENCRYPT_DNS=1
GHOST_NET_TOR_ENABLE=1
EOF

# Create startup script
cat > $MOUNT_ROOT/etc/init.d/ghost << EOF
#!/bin/sh
/usr/local/bin/ghostc-init

# Enable stealth mode
echo 1 > /proc/sys/net/ipv4/tcp_timestamps
echo 1 > /proc/sys/net/ipv4/icmp_echo_ignore_all
EOF
chmod +x $MOUNT_ROOT/etc/init.d/ghost

# Set up auto-login
mkdir -p $MOUNT_ROOT/etc/systemd/system/getty@tty1.service.d/
cat > $MOUNT_ROOT/etc/systemd/system/getty@tty1.service.d/autologin.conf << EOF
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin ghost --noclear %I \$TERM
EOF

# Create first boot script
cat > $MOUNT_ROOT/root/first_boot.sh << EOF
#!/bin/bash
# Initialize GhostC environment
ghostc-init --setup
# Generate secure keys
ghostc-keygen
# Enable hardware optimizations
ghostc-optimize --target=zero-w
EOF
chmod +x $MOUNT_ROOT/root/first_boot.sh

# Set up secure boot
cat > $MOUNT_BOOT/config.txt << EOF
# GhostOS secure boot config
arm_64bit=0
kernel=kernel7.img
gpu_mem=16
dtoverlay=miniuart-bt
enable_uart=1
# Security features
disable_commandline_tags=1
disable_overscan=1
boot_delay=0
EOF

# Create minimal fstab
cat > $MOUNT_ROOT/etc/fstab << EOF
# GhostOS fstab
/dev/mmcblk0p1  /boot           vfat    defaults,ro     0       2
/dev/mmcblk0p2  /              ext4    defaults,noatime 0       1
tmpfs           /tmp            tmpfs   defaults,nosuid,nodev 0  0
tmpfs           /var/log        tmpfs   defaults,nosuid,nodev 0  0
EOF

# Set up secure memory management
cat > $MOUNT_ROOT/etc/sysctl.d/99-ghost-security.conf << EOF
# Memory security
kernel.kptr_restrict=2
kernel.dmesg_restrict=1
kernel.printk=3 3 3 3
kernel.unprivileged_bpf_disabled=1
kernel.exec-shield=2
kernel.randomize_va_space=2
EOF

# Clean up
sync
umount $MOUNT_BOOT
umount $MOUNT_ROOT

echo "GhostOS finalization complete!"
echo "Your SD card is ready. Insert it into your Raspberry Pi Zero W and power on."
echo "On first boot, the system will run first_boot.sh automatically."
