#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/types.h>
#include <sys/stat.h>
#include "ghost.h"

// GPIO control functions
int ghost_gpio_init(int pin) {
    char buf[64];
    int fd;
    
    // Export GPIO
    fd = open("/sys/class/gpio/export", O_WRONLY);
    if (fd < 0) return -1;
    
    snprintf(buf, sizeof(buf), "%d", pin);
    write(fd, buf, strlen(buf));
    close(fd);
    
    // Set direction
    snprintf(buf, sizeof(buf), "/sys/class/gpio/gpio%d/direction", pin);
    fd = open(buf, O_WRONLY);
    if (fd < 0) return -1;
    
    write(fd, "out", 3);
    close(fd);
    
    return 0;
}

int ghost_gpio_set(int pin, int value) {
    char buf[64];
    int fd;
    
    snprintf(buf, sizeof(buf), "/sys/class/gpio/gpio%d/value", pin);
    fd = open(buf, O_WRONLY);
    if (fd < 0) return -1;
    
    write(fd, value ? "1" : "0", 1);
    close(fd);
    
    return 0;
}

// System mode control
int ghost_set_mode(int mode) {
    switch(mode) {
        case GHOST_MODE_STEALTH:
            system("/usr/local/lib/ghostc/ghostc-stealth --enable");
            break;
        case GHOST_MODE_SECURE:
            // Enable secure memory and process restrictions
            system("echo 2 > /proc/sys/kernel/randomize_va_space");
            system("echo 1 > /proc/sys/kernel/dmesg_restrict");
            break;
        case GHOST_MODE_NORMAL:
            system("/usr/local/lib/ghostc/ghostc-stealth --disable");
            system("echo 1 > /proc/sys/kernel/randomize_va_space");
            system("echo 0 > /proc/sys/kernel/dmesg_restrict");
            break;
        default:
            return -1;
    }
    return 0;
}

// Initialize GhostC system
int ghost_init(void) {
    printf("Initializing GhostC v%s\n", GHOST_VERSION);
    
    // Read configuration
    FILE *config = fopen("/etc/ghost/config", "r");
    if (!config) {
        fprintf(stderr, "Error: Cannot read configuration\n");
        return -1;
    }
    fclose(config);
    
    // Initialize GPIO system
    if (ghost_gpio_init(GHOST_GPIO_18) < 0 ||
        ghost_gpio_init(GHOST_GPIO_23) < 0 ||
        ghost_gpio_init(GHOST_GPIO_24) < 0 ||
        ghost_gpio_init(GHOST_GPIO_25) < 0) {
        fprintf(stderr, "Warning: GPIO initialization failed\n");
    }
    
    return 0;
}
