#!/bin/bash

# Safety check function
check_device() {
    local device=$1
    
    # Check if device exists
    if [ ! -b "$device" ]; then
        echo "Error: Device $device not found"
        exit 1
    }
    
    # Ensure it's not the system drive
    if mount | grep "on / " | grep -q "$device"; then
        echo "Error: $device appears to be your system drive! Operation aborted for safety."
        exit 1
    }
    
    # Get user confirmation
    echo "WARNING: This will format $device. ALL DATA WILL BE LOST!"
    echo "Please verify this is your SD card and not your system drive."
    read -p "Type 'YES' in capitals to continue: " confirm
    if [ "$confirm" != "YES" ]; then
        echo "Operation cancelled by user"
        exit 1
    }
}

# Pi Zero W specific configurations
setup_pizero_config() {
    local boot_path=$1
    
    cat > "${boot_path}/config.txt" << "EOF"
# Safe GhostOS config for Pi Zero W
# Processor settings
arm_64bit=0
arm_freq=1000
over_voltage=0
force_turbo=0

# Memory split (minimum GPU memory as we don't need graphics)
gpu_mem=16

# Enable UART but disable Bluetooth (safer option)
enable_uart=1
dtoverlay=disable-bt

# Disable HDMI to save power (can be enabled later)
hdmi_blanking=2

# Disable WiFi by default (can be enabled via ghostc)
dtoverlay=disable-wifi

# Temperature protection
temp_limit=85
EOF
}

# Main script
echo "GhostOS Safe Setup for Pi Zero W"
echo "--------------------------------"

# Get device name
read -p "Enter your SD card device (e.g., /dev/sdb): " DEVICE
check_device "$DEVICE"

# Create a dry-run function to show what would happen
echo "The following operations will be performed:"
echo "1. Format $DEVICE with:"
echo "   - FAT32 boot partition (256MB)"
echo "   - ext4 root partition (remaining space)"
echo "2. Install minimal GhostOS components"
echo "3. Configure safe Pi Zero W settings"
echo "4. Set up GhostC in minimal mode"

read -p "Continue with setup? (yes/no): " proceed
if [ "$proceed" != "yes" ]; then
    echo "Setup cancelled"
    exit 0
fi

echo "Setup will begin in 5 seconds... Press Ctrl+C to cancel"
sleep 5

# Rest of the script would go here...
echo "This is currently in dry-run mode for safety."
echo "Please review the script and configurations before proceeding with actual installation."
