#pragma once

#include <string>
#include <vector>
#include <functional>

namespace ghost {
namespace wifi {

class WiFiCore {
public:
    WiFiCore();
    ~WiFiCore();

    // Core WiFi operations
    bool initialize();
    bool connect(const std::string& ssid, const std::string& psk);
    void disconnect();
    bool is_connected();
    
    // Network scanning
    struct Network {
        std::string ssid;
        int signal_strength;  // dBm
        bool encrypted;
    };
    std::vector<Network> scan();
    
    // Low-level control
    bool set_power_save(bool enable);
    bool set_tx_power(int dbm);  // Usually 20dBm max for Pi Zero W
    bool set_channel(int channel);
    
    // Status and monitoring
    struct Stats {
        int tx_packets;
        int rx_packets;
        int tx_failed;
        int retries;
        float link_quality;
        int signal_level;
        int noise_level;
    };
    Stats get_stats();
    
    // Event callbacks
    using ConnectionCallback = std::function<void(bool)>;
    void on_connection_change(ConnectionCallback callback);
    
private:
    // Direct hardware access
    void reset_hardware();
    bool configure_hardware();
    void setup_interrupts();
    
    // Low-level operations
    bool send_command(uint32_t cmd);
    bool wait_for_response();
    void handle_interrupt();
    
    // Internal state
    struct {
        bool initialized;
        bool connected;
        int current_channel;
        int tx_power;
        bool power_save;
    } state_;
};

} // namespace wifi
} // namespace ghost
