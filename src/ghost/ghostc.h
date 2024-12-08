#ifndef GHOSTC_H
#define GHOSTC_H

#include <stdint.h>
#include <stdbool.h>

// GhostC Version
#define GHOSTC_VERSION "1.0.0"
#define GHOSTC_API_VERSION 1

// System modes
typedef enum {
    GHOST_MODE_NORMAL = 0,
    GHOST_MODE_STEALTH = 1,
    GHOST_MODE_SECURE = 2,
    GHOST_MODE_NEURAL = 3
} ghost_mode_t;

// Hardware interfaces
typedef enum {
    GHOST_GPIO = 0,
    GHOST_SPI = 1,
    GHOST_I2C = 2,
    GHOST_UART = 3
} ghost_interface_t;

// Security levels
typedef enum {
    GHOST_SEC_NONE = 0,
    GHOST_SEC_LOW = 1,
    GHOST_SEC_MED = 2,
    GHOST_SEC_HIGH = 3,
    GHOST_SEC_PARANOID = 4
} ghost_security_t;

// Neural network types
typedef enum {
    GHOST_NN_BASIC = 0,
    GHOST_NN_CONV = 1,
    GHOST_NN_RNN = 2,
    GHOST_NN_TRANSFORMER = 3
} ghost_neural_t;

// Core functions
int ghost_init(void);
int ghost_shutdown(void);
int ghost_set_mode(ghost_mode_t mode);
int ghost_get_mode(ghost_mode_t *mode);

// Hardware control
int ghost_hw_init(ghost_interface_t interface);
int ghost_hw_deinit(ghost_interface_t interface);
int ghost_gpio_set(uint8_t pin, bool value);
int ghost_gpio_get(uint8_t pin, bool *value);

// Security functions
int ghost_secure_memory(void);
int ghost_secure_network(void);
int ghost_set_security(ghost_security_t level);
int ghost_get_security(ghost_security_t *level);

// Neural network functions
int ghost_neural_init(ghost_neural_t type);
int ghost_neural_train(const uint8_t *data, size_t size);
int ghost_neural_predict(const uint8_t *input, uint8_t *output);

// System monitoring
int ghost_monitor_start(void);
int ghost_monitor_stop(void);
int ghost_get_stats(void *stats, size_t size);

#endif /* GHOSTC_H */
