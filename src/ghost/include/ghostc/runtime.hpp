#pragma once

#include <cstdint>
#include <memory>

namespace ghost {
namespace runtime {

// Optimized runtime for Pi Zero W
class Runtime {
public:
    // Memory management optimized for ARM
    struct Memory {
        static void* alloc_fast(size_t size) {
            // L1 cache aligned allocation
            return aligned_alloc(32, size);
        }
        
        static void* alloc_dma(size_t size) {
            // DMA-capable memory for hardware ops
            return aligned_alloc(4096, size);
        }
        
        template<typename T>
        static T* alloc_array(size_t count) {
            return static_cast<T*>(alloc_fast(count * sizeof(T)));
        }
    };

    // Hardware acceleration
    struct Hardware {
        // NEON SIMD operations
        static void memcpy_neon(void* dst, const void* src, size_t size);
        static void memset_neon(void* dst, int value, size_t size);
        static void vector_add_neon(float* c, const float* a, const float* b, size_t size);
        static void vector_mul_neon(float* c, const float* a, const float* b, size_t size);
        
        // Direct GPIO access
        static void gpio_set(int pin) { *(gpio_base + 7) = 1 << pin; }
        static void gpio_clr(int pin) { *(gpio_base + 10) = 1 << pin; }
        static bool gpio_get(int pin) { return *(gpio_base + 13) & (1 << pin); }
        
        // Hardware PWM
        static void pwm_set(int channel, uint16_t value);
        static void pwm_enable(int channel, bool enable);
    };

    // Neural operations
    struct Neural {
        // 8-bit quantized operations
        static void quantize_weights(float* weights, uint8_t* quantized, size_t size);
        static void dequantize_output(uint8_t* quantized, float* output, size_t size);
        
        // NEON-optimized layer operations
        static void dense_forward_q8(const uint8_t* input, const uint8_t* weights, 
                                   uint8_t* output, size_t in_size, size_t out_size);
        static void conv1d_q8(const uint8_t* input, const uint8_t* kernel,
                            uint8_t* output, size_t size, size_t kernel_size);
    };

    // Async operations
    struct Async {
        static void yield();
        static void sleep_ms(uint32_t ms);
        static uint64_t get_time_us();
        static void set_timer(uint32_t ms, void (*callback)());
    };

private:
    static volatile uint32_t* gpio_base;  // Direct hardware mapping
    static volatile uint32_t* pwm_base;
};

// Assembly optimizations
extern "C" {
    // Fast math operations
    float fast_sqrt(float x);
    float fast_inv_sqrt(float x);
    float fast_exp(float x);
    float fast_tanh(float x);

    // NEON helpers
    void neon_float_add(float* dst, const float* a, const float* b, int count);
    void neon_float_mul(float* dst, const float* a, const float* b, int count);
    void neon_quantize(const float* src, uint8_t* dst, int count);
}

} // namespace runtime
} // namespace ghost
