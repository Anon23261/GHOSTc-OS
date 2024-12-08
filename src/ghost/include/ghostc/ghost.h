#ifndef GHOST_H
#define GHOST_H

// GhostC main header file
#define GHOST_VERSION "1.0.0"

// GPIO definitions for Pi Zero W
#define GHOST_GPIO_18 18
#define GHOST_GPIO_23 23
#define GHOST_GPIO_24 24
#define GHOST_GPIO_25 25

// System modes
#define GHOST_MODE_NORMAL    0
#define GHOST_MODE_STEALTH   1
#define GHOST_MODE_SECURE    2

// Function prototypes
int ghost_init(void);
int ghost_set_mode(int mode);
int ghost_gpio_init(int pin);
int ghost_gpio_set(int pin, int value);

#endif /* GHOST_H */
