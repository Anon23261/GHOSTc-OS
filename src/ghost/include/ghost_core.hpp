#pragma once

#include <memory>
#include <string>
#include <vector>

namespace ghost {

// Forward declarations
class WiFiManager;
class MemoryManager;
class SystemManager;

class GhostCore {
public:
    static GhostCore& instance() {
        static GhostCore instance;
        return instance;
    }

    // System control
    bool initialize();
    void shutdown();
    void reboot();
    
    // Hardware access
    struct GPIO {
        enum Mode { INPUT, OUTPUT, ALT0, ALT1, ALT2, ALT3, ALT4, ALT5 };
        static void setup(int pin, Mode mode);
        static void write(int pin, bool value);
        static bool read(int pin);
        static void pwm(int pin, int value); // 0-1024
    };

    // Memory management
    struct Memory {
        size_t total;
        size_t used;
        size_t free;
        size_t shared;
        size_t buffers;
        size_t cached;
        
        static Memory get_stats();
        static void optimize();
        static void clear_cache();
    };

    // Network control
    struct Network {
        struct WiFiConfig {
            std::string ssid;
            std::string psk;
            bool hidden = false;
            std::string country = "US";
        };
        
        static bool connect_wifi(const WiFiConfig& config);
        static void disconnect_wifi();
        static bool is_connected();
        static std::vector<std::string> scan_networks();
        static std::string get_ip();
    };

    // Process management
    struct Process {
        pid_t pid;
        std::string name;
        int cpu_usage;
        size_t memory_usage;
        
        static std::vector<Process> list();
        static bool kill(pid_t pid);
        static bool start(const std::string& command);
    };

    // Power management
    struct Power {
        enum class Governor {
            POWERSAVE,
            ONDEMAND,
            PERFORMANCE
        };
        
        static void set_governor(Governor gov);
        static void set_frequency(unsigned int freq_mhz);
        static unsigned int get_temperature();
        static void throttle(bool enable);
    };

private:
    GhostCore() = default;
    ~GhostCore() = default;
    GhostCore(const GhostCore&) = delete;
    GhostCore& operator=(const GhostCore&) = delete;

    std::unique_ptr<WiFiManager> wifi_;
    std::unique_ptr<MemoryManager> memory_;
    std::unique_ptr<SystemManager> system_;
};

} // namespace ghost
