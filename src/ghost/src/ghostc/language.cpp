#include "ghostc/language.hpp"
#include <arm_neon.h>
#include <regex>
#include <map>

namespace ghost {
namespace lang {

Language::Directive Language::parse_directive(const std::string& line) {
    Directive dir;
    
    // Parse directive name and arguments
    std::regex directive_pattern("@([a-zA-Z_][a-zA-Z0-9_]*)\\s*\\(([^)]*)\\)");
    std::smatch matches;
    
    if (std::regex_search(line, matches, directive_pattern)) {
        dir.name = matches[1].str();
        
        // Parse arguments
        std::string args = matches[2].str();
        std::regex arg_pattern("\\s*([^,]+)\\s*,?");
        
        auto args_begin = std::sregex_iterator(args.begin(), args.end(), arg_pattern);
        auto args_end = std::sregex_iterator();
        
        for (auto i = args_begin; i != args_end; ++i) {
            dir.args.push_back((*i)[1].str());
        }
        
        // Check if Zero W specific
        dir.is_zero_specific = is_zero_directive(dir.name);
    }
    
    return dir;
}

bool Language::validate_zero_code(const std::string& code) {
    // Check for Zero W specific hardware features
    std::map<std::string, bool> features = {
        {"neon", false},    // NEON not available on Zero W
        {"vfp", true},      // VFP is available
        {"gpio", true},     // GPIO available
        {"i2c", true},      // I2C available
        {"spi", true},      // SPI available
        {"pwm", true}       // Hardware PWM available
    };
    
    // Parse all directives
    std::regex directive_pattern("@([a-zA-Z_][a-zA-Z0-9_]*)");
    auto begin = std::sregex_iterator(code.begin(), code.end(), directive_pattern);
    auto end = std::sregex_iterator();
    
    for (auto i = begin; i != end; ++i) {
        std::string feature = (*i)[1].str();
        if (features.count(feature) > 0 && !features[feature]) {
            return false;  // Using unsupported feature
        }
    }
    
    return true;
}

std::string Language::generate_zero_code(const std::string& source) {
    std::string optimized = source;
    
    // Replace NEON operations with VFP
    std::regex neon_pattern("@neon\\s*\\{([^}]+)\\}");
    optimized = std::regex_replace(optimized, neon_pattern, "@vfp { $1 }");
    
    // Add Zero W specific optimizations
    optimized = optimize_for_zero(optimized);
    
    return optimized;
}

bool Language::is_zero_directive(const std::string& directive) {
    static const std::vector<std::string> zero_directives = {
        "gpio", "pwm", "spi", "i2c", "cache", "vfp", "zero"
    };
    
    return std::find(zero_directives.begin(), zero_directives.end(), directive) 
           != zero_directives.end();
}

bool Language::check_hardware_compatibility(const std::string& feature) {
    // Check if feature is supported by Pi Zero W hardware
    static const std::map<std::string, bool> hardware_support = {
        {"arm11", true},
        {"armv6", true},
        {"vfp", true},
        {"neon", false},
        {"gpio", true},
        {"i2c", true},
        {"spi", true},
        {"pwm", true},
        {"usb", true},
        {"wifi", true}
    };
    
    return hardware_support.count(feature) > 0 && hardware_support.at(feature);
}

std::string Language::optimize_for_zero(const std::string& code) {
    std::string optimized = code;
    
    // Add cache alignment directives
    optimized = std::regex_replace(optimized, 
        std::regex("memory\\.alloc"),
        "memory.alloc_aligned(32)");
    
    // Add VFP optimization hints
    optimized = std::regex_replace(optimized, 
        std::regex("@neural\\s*\\{"),
        "@neural @vfp {");
    
    // Add hardware-specific prefetch hints
    optimized = std::regex_replace(optimized, 
        std::regex("memory\\.read"),
        "memory.prefetch.read");
    
    // Add Zero W specific GPIO optimizations
    optimized = std::regex_replace(optimized, 
        std::regex("gpio\\.write"),
        "gpio.write_fast");
    
    return optimized;
}

} // namespace lang
} // namespace ghost
