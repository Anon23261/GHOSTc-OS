#pragma once

#include <memory>
#include <string>
#include <vector>

namespace ghost {
namespace lang {

// Core GhostC language features optimized for Pi Zero W
class GhostC {
public:
    // Neural ops with minimal overhead
    struct Neural {
        enum class LayerType {
            DENSE,
            CONV1D,
            MAXPOOL
        };

        struct Layer {
            LayerType type;
            int units;
            float* weights;  // Direct memory access for speed
            
            void optimize_for_arm();  // ARM NEON optimizations
            void quantize(bool enable);  // 8-bit quantization
        };

        static Layer create_layer(LayerType type, int units);
        static void train(Layer& layer, float* data, int size);
    };

    // Direct hardware access
    struct Hardware {
        static void gpio_write(int pin, bool value);
        static bool gpio_read(int pin);
        static void i2c_write(uint8_t addr, uint8_t* data, size_t len);
        static void spi_transfer(uint8_t* tx, uint8_t* rx, size_t len);
        static void pwm_write(int channel, uint16_t value);
    };

    // Memory management
    struct Memory {
        static void* alloc_fast(size_t size);  // L1 cache aligned
        static void* alloc_dma(size_t size);   // DMA capable
        static void free_fast(void* ptr);
        static void free_dma(void* ptr);
    };

    // Networking
    struct Net {
        static bool wifi_connect(const char* ssid, const char* psk);
        static void wifi_scan();
        static bool tcp_connect(const char* host, int port);
        static void tcp_send(const uint8_t* data, size_t len);
    };

    // Compiler settings
    struct Compiler {
        enum Optimization {
            NONE,
            SPEED,
            SIZE,
            AGGRESSIVE
        };

        static void set_opt_level(Optimization level);
        static void enable_arm_neon(bool enable);
        static void enable_fast_math(bool enable);
    };
};

// Core language syntax
#define ghost_main() int main()
#define ghost_async async
#define ghost_await co_await
#define ghost_neural __attribute__((neural))
#define ghost_inline __attribute__((always_inline))
#define ghost_fast __attribute__((section(".fastcode")))

// Example GhostC code:
/*
ghost_main() {
    // Direct hardware access
    Hardware::gpio_write(18, true);
    
    // Neural network with minimal overhead
    ghost_neural void process_data(float* data) {
        auto layer = Neural::create_layer(Neural::LayerType::DENSE, 64);
        layer.optimize_for_arm();
        layer.quantize(true);
        Neural::train(layer, data, 1000);
    }
    
    // Async WiFi operations
    ghost_async void connect_wifi() {
        Net::wifi_connect("MyNetwork", "password");
        auto data = ghost_await Net::tcp_connect("ghost.ai", 443);
    }
    
    // Fast memory operations
    auto fast_mem = Memory::alloc_fast(1024);
    // ... use fast memory ...
    Memory::free_fast(fast_mem);
    
    return 0;
}
*/

} // namespace lang
} // namespace ghost
