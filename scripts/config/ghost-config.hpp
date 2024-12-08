#pragma once

namespace ghost {
namespace config {

// AI Assistant Configuration
struct AIConfig {
    // Development Assistant Settings
    static constexpr bool ENABLE_CODE_COMPLETION = true;
    static constexpr bool ENABLE_CODE_ANALYSIS = true;
    static constexpr bool ENABLE_DEBUGGING_HELP = true;
    static constexpr bool ENABLE_DOCUMENTATION_GEN = true;
    
    // System Monitoring
    static constexpr bool ENABLE_SYSTEM_MONITORING = true;
    static constexpr int MONITORING_INTERVAL_MS = 1000;
    
    // Learning Settings
    static constexpr float LEARNING_RATE = 0.001f;
    static constexpr float MEMORY_RETENTION = 0.95f;
    
    // Personality Settings
    static constexpr float DEFAULT_HELPFULNESS = 0.9f;
    static constexpr float DEFAULT_CURIOSITY = 0.8f;
    static constexpr float DEFAULT_FRIENDLINESS = 0.7f;
};

// Development Environment Settings
struct DevConfig {
    // Supported Languages
    static constexpr const char* LANGUAGES[] = {
        "C++", "Python", "Rust", "Go", "JavaScript"
    };
    
    // Build Systems
    static constexpr const char* BUILD_SYSTEMS[] = {
        "CMake", "Make", "Cargo", "npm"
    };
    
    // Editor Integration
    static constexpr bool VIM_INTEGRATION = true;
    static constexpr bool NEOVIM_INTEGRATION = true;
    static constexpr bool TMUX_INTEGRATION = true;
};

// System Paths
struct Paths {
    static constexpr const char* GHOST_HOME = "/opt/ghost";
    static constexpr const char* MODELS_DIR = "/opt/ghost/models";
    static constexpr const char* MEMORY_DB = "/opt/ghost/data/memory.db";
    static constexpr const char* CONFIG_DIR = "/opt/ghost/config";
};

// Feature Flags
struct Features {
    // Primary Features
    static constexpr bool ENABLE_DEV_ASSISTANT = true;
    static constexpr bool ENABLE_SYSTEM_OPTIMIZATION = true;
    static constexpr bool ENABLE_CODE_GENERATION = true;
    
    // Secondary Features
    static constexpr bool ENABLE_PWNAGOTCHI = true;  // Side capability
    static constexpr bool ENABLE_NETWORK_MONITORING = true;
    static constexpr bool ENABLE_POWER_MANAGEMENT = true;
};

} // namespace config
} // namespace ghost
