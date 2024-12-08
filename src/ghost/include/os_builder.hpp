#pragma once

#include <string>
#include <vector>
#include <memory>
#include <filesystem>

namespace ghost {
namespace os {

class OSBuilder {
public:
    OSBuilder();
    ~OSBuilder();

    // Build configuration
    struct BuildConfig {
        std::string arch;
        std::string target;
        std::vector<std::string> features;
        std::string optimization_level;
        bool debug_symbols;
    };

    // Kernel configuration
    struct KernelConfig {
        std::string version;
        std::vector<std::string> modules;
        std::vector<std::string> patches;
        bool custom_config;
    };

    // Build operations
    void setBuildConfig(const BuildConfig& config);
    void setKernelConfig(const KernelConfig& config);
    bool buildKernel();
    bool buildSystem();
    bool createImage();

    // Cross-compilation
    void setupCrossCompiler(const std::string& target);
    void addToolchain(const std::string& path);
    
    // Package management
    void addPackage(const std::string& name, const std::string& version);
    void removePackage(const std::string& name);
    void updatePackages();
    
    // System configuration
    void configureBootloader();
    void configureNetwork();
    void configureSecurity();
    
    // Testing
    bool testBuild();
    bool runQemu();
    std::vector<std::string> getTestResults();

private:
    // Build state
    struct BuildState {
        BuildConfig build_config;
        KernelConfig kernel_config;
        std::filesystem::path build_dir;
        std::filesystem::path output_dir;
        bool is_building;
    };
    BuildState state_;
    
    // Build tools
    struct BuildTools {
        std::string compiler;
        std::string linker;
        std::string assembler;
        std::string make_tool;
    };
    BuildTools tools_;
    
    // Helper methods
    void setupBuildEnvironment();
    void compileSources();
    void linkBinary();
    void createInitramfs();
    void installBootloader();
    void generateConfig();
};

} // namespace os
} // namespace ghost
