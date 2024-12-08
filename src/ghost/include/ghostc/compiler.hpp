#pragma once

#include <string>
#include <vector>
#include <memory>
#include <map>

namespace ghost {
namespace lang {

// Optimized GhostC Compiler for Pi Zero W
class Compiler {
public:
    Compiler();
    ~Compiler();

    // Optimized compilation for ARM11
    struct CompileOptions {
        bool optimize_arm = true;      // ARM specific optimizations
        bool use_neon = true;         // NEON SIMD instructions
        bool fast_math = true;        // Fast math operations
        bool strip_debug = true;      // Remove debug info
        int opt_level = 3;           // Max optimization
    };

    // Minimal but powerful type system
    struct Type {
        enum class Kind {
            Void,
            Int,
            Float,
            Bool,
            Neural,  // Neural type
            Array,
            Ptr
        };
        Kind kind;
        bool is_const;
    };

    // AST optimized for minimal memory
    struct AST {
        struct Node {
            virtual ~Node() = default;
            virtual Type getType() const = 0;
            bool can_optimize();
            void optimize_arm();
        };
        using NodePtr = std::shared_ptr<Node>;
    };

    // Fast compilation
    bool compile(const std::string& source);
    bool optimize();
    bool generate_code();
    
    // Memory optimizations
    void use_static_alloc(bool enable);
    void set_heap_size(size_t size);
    void enable_stack_protector(bool enable);

    // ARM optimizations
    void enable_thumb(bool enable);
    void set_fpu_mode(const std::string& mode);
    void set_cpu_flags(uint32_t flags);

    // Neural features
    void enable_neural_ops();
    void set_neural_precision(int bits);
    void optimize_neural_layers();

private:
    // Internal optimizations
    void optimize_memory_layout();
    void optimize_register_alloc();
    void optimize_instruction_scheduling();
    void eliminate_dead_code();
    
    // ARM specific
    void generate_arm_assembly();
    void apply_arm_optimizations();
    void setup_arm_registers();

    CompileOptions options_;
    std::vector<std::string> errors_;
    AST::NodePtr ast_root_;
};

} // namespace lang
} // namespace ghost
