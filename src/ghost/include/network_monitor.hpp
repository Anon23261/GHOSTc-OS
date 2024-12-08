#pragma once

#include <string>
#include <vector>
#include <memory>
#include <pcap.h>
#include <netinet/in.h>

namespace ghost {
namespace network {

class NetworkMonitor {
public:
    NetworkMonitor();
    ~NetworkMonitor();

    // Network monitoring
    void startMonitoring(const std::string& interface);
    void stopMonitoring();
    
    // Network analysis
    struct NetworkStats {
        size_t bytes_in;
        size_t bytes_out;
        size_t packets_in;
        size_t packets_out;
        std::vector<std::string> active_connections;
    };
    NetworkStats getStats();
    
    // Device discovery
    struct NetworkDevice {
        std::string mac_address;
        std::string ip_address;
        std::string hostname;
        std::string vendor;
        bool is_active;
    };
    std::vector<NetworkDevice> scanNetwork();
    
    // Traffic analysis
    struct TrafficPattern {
        std::string source;
        std::string destination;
        size_t bandwidth;
        std::string protocol;
        std::time_t timestamp;
    };
    std::vector<TrafficPattern> analyzeTraffic();

private:
    // Pcap handling
    pcap_t* pcap_handle_;
    char errbuf_[PCAP_ERRBUF_SIZE];
    
    // Monitoring state
    struct MonitorState {
        bool is_active;
        std::string interface;
        std::vector<TrafficPattern> patterns;
        NetworkStats current_stats;
    };
    MonitorState state_;
    
    // Helper methods
    void initPcap();
    void processPacket(const struct pcap_pkthdr* header, const u_char* packet);
    void updateStats(const struct pcap_pkthdr* header);
    std::string resolveHostname(const std::string& ip);
    std::string lookupVendor(const std::string& mac);
};

} // namespace network
} // namespace ghost
