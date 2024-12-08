#pragma once

#include <string>
#include <vector>
#include <memory>
#include <curl/curl.h>

namespace ghost {
namespace privacy {

class TorManager {
public:
    TorManager();
    ~TorManager();

    // Tor control
    void startTor();
    void stopTor();
    void restartTor();
    
    // Circuit management
    struct Circuit {
        std::string id;
        std::vector<std::string> nodes;
        std::string status;
        std::time_t build_time;
    };
    std::vector<Circuit> getCircuits();
    void createCircuit();
    
    // Configuration
    void setExitNode(const std::string& country);
    void setEntryNode(const std::string& node);
    void updateBridges();
    
    // Status
    struct TorStatus {
        bool is_running;
        std::string current_ip;
        std::string exit_country;
        float bandwidth_rate;
        size_t circuits_active;
    };
    TorStatus getStatus();

private:
    // Tor process
    pid_t tor_process_;
    std::string tor_config_path_;
    
    // CURL handling
    CURL* curl_;
    struct curl_slist* headers_;
    
    // Helper methods
    void initTor();
    void setupTorrc();
    void checkTorStatus();
    void manageTorProcess();
    std::string getTorControlPassword();
};

} // namespace privacy
} // namespace ghost
