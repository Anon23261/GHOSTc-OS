#include "ghostc/runtime.hpp"
#include <arm_neon.h>
#include <sys/mman.h>
#include <unistd.h>
#include <fcntl.h>

namespace ghost {
namespace runtime {

// Static member initialization
volatile uint32_t* Runtime::gpio_base = nullptr;
volatile uint32_t* Runtime::pwm_base = nullptr;

// Hardware acceleration implementations
void Runtime::Hardware::memcpy_neon(void* dst, const void* src, size_t size) {
    float32x4_t* vdst = reinterpret_cast<float32x4_t*>(dst);
    const float32x4_t* vsrc = reinterpret_cast<const float32x4_t*>(src);
    
    for (size_t i = 0; i < size / 16; i++) {
        vst1q_f32(reinterpret_cast<float*>(&vdst[i]), 
                  vld1q_f32(reinterpret_cast<const float*>(&vsrc[i])));
    }
}

void Runtime::Hardware::memset_neon(void* dst, int value, size_t size) {
    float32x4_t vvalue = vdupq_n_f32(static_cast<float>(value));
    float32x4_t* vdst = reinterpret_cast<float32x4_t*>(dst);
    
    for (size_t i = 0; i < size / 16; i++) {
        vst1q_f32(reinterpret_cast<float*>(&vdst[i]), vvalue);
    }
}

void Runtime::Hardware::vector_add_neon(float* c, const float* a, const float* b, size_t size) {
    for (size_t i = 0; i < size / 4; i++) {
        float32x4_t va = vld1q_f32(&a[i * 4]);
        float32x4_t vb = vld1q_f32(&b[i * 4]);
        vst1q_f32(&c[i * 4], vaddq_f32(va, vb));
    }
}

void Runtime::Hardware::vector_mul_neon(float* c, const float* a, const float* b, size_t size) {
    for (size_t i = 0; i < size / 4; i++) {
        float32x4_t va = vld1q_f32(&a[i * 4]);
        float32x4_t vb = vld1q_f32(&b[i * 4]);
        vst1q_f32(&c[i * 4], vmulq_f32(va, vb));
    }
}

void Runtime::Hardware::pwm_set(int channel, uint16_t value) {
    if (!pwm_base) return;
    *(pwm_base + channel) = value;
}

void Runtime::Hardware::pwm_enable(int channel, bool enable) {
    if (!pwm_base) return;
    if (enable) {
        *(pwm_base + 8) |= (1 << channel);
    } else {
        *(pwm_base + 8) &= ~(1 << channel);
    }
}

// Neural operations implementations
void Runtime::Neural::quantize_weights(float* weights, uint8_t* quantized, size_t size) {
    for (size_t i = 0; i < size / 4; i++) {
        float32x4_t vweights = vld1q_f32(&weights[i * 4]);
        float32x4_t vscaled = vmulq_n_f32(vweights, 127.0f);
        int32x4_t vint = vcvtq_s32_f32(vscaled);
        uint8x8_t vnarrow = vqmovun_s16(vcombine_s16(
            vmovn_s32(vint),
            vmovn_s32(vint)
        ));
        vst1_u8(&quantized[i * 4], vnarrow);
    }
}

void Runtime::Neural::dequantize_output(uint8_t* quantized, float* output, size_t size) {
    for (size_t i = 0; i < size / 4; i++) {
        uint8x8_t vquant = vld1_u8(&quantized[i * 4]);
        int16x8_t vint16 = vreinterpretq_s16_u16(vmovl_u8(vquant));
        int32x4_t vint32_low = vmovl_s16(vget_low_s16(vint16));
        float32x4_t vfloat = vcvtq_f32_s32(vint32_low);
        vst1q_f32(&output[i * 4], vmulq_n_f32(vfloat, 1.0f/127.0f));
    }
}

void Runtime::Neural::dense_forward_q8(const uint8_t* input, const uint8_t* weights,
                                     uint8_t* output, size_t in_size, size_t out_size) {
    for (size_t i = 0; i < out_size; i++) {
        int32x4_t vacc = vdupq_n_s32(0);
        for (size_t j = 0; j < in_size / 16; j++) {
            uint8x16_t vin = vld1q_u8(&input[j * 16]);
            uint8x16_t vw = vld1q_u8(&weights[(i * in_size) + j * 16]);
            
            int16x8_t vproduct_low = vmull_u8(vget_low_u8(vin), vget_low_u8(vw));
            int16x8_t vproduct_high = vmull_u8(vget_high_u8(vin), vget_high_u8(vw));
            
            vacc = vpadalq_s16(vacc, vproduct_low);
            vacc = vpadalq_s16(vacc, vproduct_high);
        }
        
        int32_t acc = vaddvq_s32(vacc);
        output[i] = static_cast<uint8_t>(std::min(255, std::max(0, acc / 128)));
    }
}

void Runtime::Neural::conv1d_q8(const uint8_t* input, const uint8_t* kernel,
                               uint8_t* output, size_t size, size_t kernel_size) {
    for (size_t i = 0; i < size - kernel_size + 1; i++) {
        int32x4_t vacc = vdupq_n_s32(0);
        for (size_t j = 0; j < kernel_size / 4; j++) {
            uint8x8_t vin = vld1_u8(&input[i + j * 4]);
            uint8x8_t vk = vld1_u8(&kernel[j * 4]);
            int16x8_t vproduct = vmull_u8(vin, vk);
            vacc = vpadalq_s16(vacc, vproduct);
        }
        output[i] = static_cast<uint8_t>(vaddvq_s32(vacc) / kernel_size);
    }
}

// Async operations implementations
void Runtime::Async::yield() {
    sched_yield();
}

void Runtime::Async::sleep_ms(uint32_t ms) {
    usleep(ms * 1000);
}

uint64_t Runtime::Async::get_time_us() {
    struct timespec ts;
    clock_gettime(CLOCK_MONOTONIC, &ts);
    return ts.tv_sec * 1000000ULL + ts.tv_nsec / 1000;
}

void Runtime::Async::set_timer(uint32_t ms, void (*callback)()) {
    // Simple timer implementation using POSIX timer
    timer_t timer_id;
    struct sigevent sev;
    struct itimerspec its;

    sev.sigev_notify = SIGEV_THREAD;
    sev.sigev_notify_function = callback;
    sev.sigev_notify_attributes = nullptr;
    timer_create(CLOCK_REALTIME, &sev, &timer_id);

    its.it_value.tv_sec = ms / 1000;
    its.it_value.tv_nsec = (ms % 1000) * 1000000;
    its.it_interval.tv_sec = 0;
    its.it_interval.tv_nsec = 0;

    timer_settime(timer_id, 0, &its, nullptr);
}

// Assembly optimized implementations
extern "C" {

float fast_sqrt(float x) {
    float result;
    asm volatile(
        "vsqrt.f32 %0, %1"
        : "=w"(result)
        : "w"(x)
    );
    return result;
}

float fast_inv_sqrt(float x) {
    float xhalf = 0.5f * x;
    int i = *(int*)&x;
    i = 0x5f3759df - (i >> 1);
    x = *(float*)&i;
    x = x * (1.5f - xhalf * x * x);
    return x;
}

float fast_exp(float x) {
    float result;
    asm volatile(
        "vexp.f32 %0, %1"
        : "=w"(result)
        : "w"(x)
    );
    return result;
}

float fast_tanh(float x) {
    float exp2x = fast_exp(2.0f * x);
    return (exp2x - 1.0f) / (exp2x + 1.0f);
}

void neon_float_add(float* dst, const float* a, const float* b, int count) {
    for (int i = 0; i < count / 4; i++) {
        float32x4_t va = vld1q_f32(&a[i * 4]);
        float32x4_t vb = vld1q_f32(&b[i * 4]);
        vst1q_f32(&dst[i * 4], vaddq_f32(va, vb));
    }
}

void neon_float_mul(float* dst, const float* a, const float* b, int count) {
    for (int i = 0; i < count / 4; i++) {
        float32x4_t va = vld1q_f32(&a[i * 4]);
        float32x4_t vb = vld1q_f32(&b[i * 4]);
        vst1q_f32(&dst[i * 4], vmulq_f32(va, vb));
    }
}

void neon_quantize(const float* src, uint8_t* dst, int count) {
    for (int i = 0; i < count / 4; i++) {
        float32x4_t vsrc = vld1q_f32(&src[i * 4]);
        float32x4_t vscaled = vmulq_n_f32(vsrc, 127.0f);
        int32x4_t vint = vcvtq_s32_f32(vscaled);
        uint8x8_t vnarrow = vqmovun_s16(vcombine_s16(
            vmovn_s32(vint),
            vmovn_s32(vint)
        ));
        vst1_u8(&dst[i * 4], vnarrow);
    }
}

} // extern "C"

} // namespace runtime
} // namespace ghost
