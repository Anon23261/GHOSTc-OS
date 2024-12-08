#pragma once

#include <string>
#include <vector>
#include <memory>
#include <functional>

namespace ghost {
namespace network {

class WifiManager {
public:
    WifiManager();
    ~WifiManager();

    // WiFi structures
    struct Network {
        std::string ssid;
        std::string bssid;
        int signal_strength;
        bool is_secure;
        std::string encryption_type;
        bool is_connected;
    };

    struct ConnectionConfig {
        std::string ssid;
        std::string password;
        bool auto_connect;
        bool hidden_network;
        std::string ip_config;  // "dhcp" or "static"
        std::string static_ip;
        std::string gateway;
        std::string dns;
    };

    // Core functionality
    bool initialize();
    bool startScan();
    std::vector<Network> getNetworks();
    bool connect(const ConnectionConfig& config);
    bool disconnect();
    bool isConnected();

    // Advanced features
    void enableHotspot(const std::string& ssid, const std::string& password);
    void disableHotspot();
    void enableMeshNetwork();
    void addMeshPeer(const std::string& peer_id);

    // Security
    void setSecurityProtocol(const std::string& protocol);
    void enableFirewall();
    void addFirewallRule(const std::string& rule);

    // Monitoring
    struct Stats {
        int tx_bytes;
        int rx_bytes;
        int signal_level;
        std::string current_ssid;
        std::string current_bssid;
        int channel;
        std::string frequency;
    };
    Stats getStats();

    // Event handling
    using NetworkCallback = std::function<void(const Network&)>;
    void onNetworkFound(NetworkCallback callback);
    void onConnectionChanged(NetworkCallback callback);
    void onSignalStrengthChanged(NetworkCallback callback);

private:
    // Internal state
    struct WifiState {
        bool initialized;
        bool scanning;
        Network current_network;
        std::vector<Network> available_networks;
    };
    WifiState state_;

    // Driver interaction
    void initializeDriver();
    void configureDevice();
    void handleEvents();
    void updateState();
};

} // namespace network
} // namespace ghost
