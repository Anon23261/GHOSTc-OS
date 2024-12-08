#pragma once

#include <string>
#include <vector>
#include <memory>

namespace ghost {
namespace kernel {

class KernelDev {
public:
    KernelDev();
    ~KernelDev();

    // Kernel development
    void configureKernel();
    void buildKernel();
    void installModules();
    void testKernel();
    
    // Module development
    struct Module {
        std::string name;
        std::string version;
        bool loaded;
        std::vector<std::string> dependencies;
    };
    
    void createModule(const std::string& name);
    void buildModule(const std::string& name);
    void loadModule(const std::string& name);
    void unloadModule(const std::string& name);
    
    // Debugging
    void setupKgdb();
    void attachDebugger();
    void setBreakpoint(const std::string& location);
    
    // Analysis
    struct SystemInfo {
        std::string kernel_version;
        std::vector<Module> loaded_modules;
        std::map<std::string, std::string> system_params;
    };
    
    SystemInfo getSystemInfo();
    void analyzePerformance();
    void checkMemoryUsage();

private:
    // Kernel state
    struct KernelState {
        std::string version;
        std::string config_path;
        std::vector<Module> modules;
        bool debugging_enabled;
    };
    KernelState state_;
    
    // Build environment
    struct BuildEnv {
        std::string kernel_src;
        std::string build_dir;
        std::string install_dir;
        std::vector<std::string> flags;
    };
    BuildEnv env_;
    
    // Helper methods
    void setupBuildEnv();
    void prepareSources();
    void compileKernel();
    void installKernel();
    void updateBootloader();
};

} // namespace kernel
} // namespace ghost
