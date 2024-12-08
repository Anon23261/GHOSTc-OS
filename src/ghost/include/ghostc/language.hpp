#pragma once

#include <string>
#include <vector>
#include <memory>

namespace ghost {
namespace lang {

// GhostC Language Specification for Pi Zero W
class Language {
public:
    // Core language keywords
    static constexpr const char* KEYWORDS[] = {
        "ghost",         // Program entry
        "neural",        // Neural operation
        "secure",        // Security context
        "stealth",       // Stealth operation
        "hardware",      // Direct hardware access
        "fast",          // Speed-optimized
        "async",         // Asynchronous operation
        "memory",        // Memory management
        "encrypt",       // Encryption operation
        "zero",          // Zero-specific operation
    };

    // Pi Zero W specific directives
    struct ZeroDirectives {
        static constexpr const char* GPIO = "@gpio";      // Direct GPIO access
        static constexpr const char* PWM = "@pwm";        // Hardware PWM
        static constexpr const char* SPI = "@spi";        // SPI bus access
        static constexpr const char* I2C = "@i2c";        // I2C bus access
        static constexpr const char* CACHE = "@cache";    // Cache control
        static constexpr const char* NEON = "@neon";      // NEON optimization
        static constexpr const char* VFP = "@vfp";        // VFP optimization
    };

    // Memory access specifiers
    enum class MemoryType {
        FAST,       // L1 cache optimized
        SECURE,     // Encrypted memory
        DMA,        // DMA capable
        SHARED      // Shared memory
    };

    // Hardware access modes
    enum class HardwareMode {
        DIRECT,     // Direct register access
        KERNEL,     // Through kernel
        STEALTH     // Hidden access
    };

    // Neural operation types
    enum class NeuralOp {
        DENSE,      // Dense layer
        CONV,       // Convolution
        POOL,       // Pooling
        QUANTUM     // Quantum operation
    };

    // Example GhostC syntax:
    /*
    @ghost_program
    void main() {
        // Direct hardware access
        @gpio(18) {
            pin.mode = OUTPUT;
            pin.write(HIGH);
        }

        // Neural operation with NEON
        @neural @neon {
            layer = neural.dense(64);
            layer.optimize();
            layer.train(data);
        }

        // Secure memory operation
        @secure @memory {
            data = memory.alloc(1024);
            data.encrypt();
            data.lock();
        }

        // Stealth network operation
        @stealth @async {
            net = network.connect("target");
            net.hide();
            await net.send(data);
        }

        // Zero-specific optimization
        @zero @cache {
            memory.align(32);
            memory.prefetch();
            neon.enable();
        }
    }
    */

    // Compiler directives
    struct Directive {
        std::string name;
        std::vector<std::string> args;
        bool is_zero_specific;
    };

    // Parse directives
    static Directive parse_directive(const std::string& line);
    
    // Validate Zero W specific code
    static bool validate_zero_code(const std::string& code);
    
    // Generate optimized code
    static std::string generate_zero_code(const std::string& source);

private:
    // Internal helpers
    static bool is_zero_directive(const std::string& directive);
    static bool check_hardware_compatibility(const std::string& feature);
    static std::string optimize_for_zero(const std::string& code);
};

// Language macros for Zero W
#define ghost_program __attribute__((section(".ghost_text"))) int main()
#define ghost_neural __attribute__((target("arch=armv6,+vfp")))
#define ghost_secure __attribute__((section(".secure_text")))
#define ghost_fast __attribute__((optimize("O2"), target("arch=armv6,+vfp")))
#define ghost_async __attribute__((async))

// Hardware-specific macros
#define zero_gpio(pin) __asm__ volatile("mcr p15, 0, %0, c1, c0, 0" : : "r" (pin))
#define zero_cache_flush() __asm__ volatile("mcr p15, 0, %0, c7, c10, 0" : : "r" (0))
#define zero_neon_enable() __asm__ volatile("vmrs r0, fpexc \n orr r0, #0x40000000 \n vmsr fpexc, r0")

} // namespace lang
} // namespace ghost
