#ifndef GHOST_FLIPPER_H
#define GHOST_FLIPPER_H

#include <stdint.h>
#include <stdbool.h>

// Flipper-like subsystems
typedef enum {
    GHOST_SUB_RFID = 0,
    GHOST_SUB_NFC = 1,
    GHOST_SUB_SUBGHZ = 2,
    GHOST_SUB_IR = 3,
    GHOST_SUB_IBUTTON = 4,
    GHOST_SUB_BAD_USB = 5,
    GHOST_SUB_BLUETOOTH = 6,
    GHOST_SUB_GPIO = 7
} ghost_subsystem_t;

// Protocol definitions
typedef enum {
    // SubGHz protocols
    GHOST_PROTO_AM270 = 0,
    GHOST_PROTO_AM650 = 1,
    GHOST_PROTO_FM238 = 2,
    GHOST_PROTO_FM476 = 3,
    GHOST_PROTO_KEELOQ = 4,
    
    // RFID protocols
    GHOST_PROTO_EM4100 = 100,
    GHOST_PROTO_HIDProx = 101,
    GHOST_PROTO_INDALA = 102,
    
    // NFC protocols
    GHOST_PROTO_MIFARE = 200,
    GHOST_PROTO_NTAG = 201,
    GHOST_PROTO_ISO14443A = 202,
    
    // IR protocols
    GHOST_PROTO_NEC = 300,
    GHOST_PROTO_SAMSUNG = 301,
    GHOST_PROTO_RC5 = 302,
    GHOST_PROTO_RC6 = 303
} ghost_protocol_t;

// Frequency bands
typedef enum {
    GHOST_FREQ_300 = 300000000,
    GHOST_FREQ_315 = 315000000,
    GHOST_FREQ_433 = 433920000,
    GHOST_FREQ_868 = 868350000,
    GHOST_FREQ_915 = 915000000
} ghost_frequency_t;

// Function prototypes

// Subsystem control
int ghost_flipper_init(ghost_subsystem_t subsystem);
int ghost_flipper_deinit(ghost_subsystem_t subsystem);
bool ghost_flipper_is_enabled(ghost_subsystem_t subsystem);

// RFID functions
int ghost_rfid_read(uint8_t *data, size_t *size);
int ghost_rfid_write(const uint8_t *data, size_t size);
int ghost_rfid_emulate(const uint8_t *data, size_t size);

// NFC functions
int ghost_nfc_scan(void);
int ghost_nfc_read(uint8_t *data, size_t *size);
int ghost_nfc_write(const uint8_t *data, size_t size);
int ghost_nfc_emulate(const uint8_t *data, size_t size);

// SubGHz functions
int ghost_subghz_scan(ghost_frequency_t freq);
int ghost_subghz_transmit(ghost_frequency_t freq, const uint8_t *data, size_t size);
int ghost_subghz_receive(ghost_frequency_t freq, uint8_t *data, size_t *size);
int ghost_subghz_replay(ghost_frequency_t freq);

// IR functions
int ghost_ir_receive(uint32_t *code, ghost_protocol_t *protocol);
int ghost_ir_transmit(uint32_t code, ghost_protocol_t protocol);
int ghost_ir_learn(void);

// Bad USB functions
int ghost_badusb_load_script(const char *filename);
int ghost_badusb_run_script(void);
int ghost_badusb_stop(void);

// iButton functions
int ghost_ibutton_read(uint8_t *id);
int ghost_ibutton_write(const uint8_t *id);
int ghost_ibutton_emulate(const uint8_t *id);

// Bluetooth functions
int ghost_bt_scan(void);
int ghost_bt_connect(const char *addr);
int ghost_bt_send(const uint8_t *data, size_t size);

#endif /* GHOST_FLIPPER_H */
