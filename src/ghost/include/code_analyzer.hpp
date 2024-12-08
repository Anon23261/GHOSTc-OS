#pragma once

#include <string>
#include <vector>
#include <memory>
#include <unordered_map>
#include "clang/AST/AST.h"
#include "clang/Basic/Diagnostic.h"

namespace ghost {
namespace dev {

class CodeAnalyzer {
public:
    CodeAnalyzer();
    ~CodeAnalyzer();

    struct Analysis {
        std::vector<std::string> suggestions;
        std::vector<std::string> warnings;
        std::vector<std::string> errors;
        std::vector<std::string> style_issues;
        float complexity_score;
        float maintainability_index;
    };

    // Code analysis
    Analysis analyzeCode(const std::string& code);
    std::vector<std::string> findPatterns(const std::string& code);
    std::vector<std::string> suggestOptimizations(const std::string& code);
    
    // Security analysis
    struct SecurityIssue {
        std::string type;
        std::string description;
        std::string severity;
        std::string fix_suggestion;
    };
    std::vector<SecurityIssue> checkSecurity(const std::string& code);
    
    // Performance analysis
    struct PerformanceMetrics {
        float time_complexity;
        float space_complexity;
        std::vector<std::string> bottlenecks;
        std::vector<std::string> optimization_suggestions;
    };
    PerformanceMetrics analyzePerformance(const std::string& code);
    
    // Code quality
    struct QualityMetrics {
        float maintainability;
        float readability;
        float test_coverage;
        std::vector<std::string> improvement_suggestions;
    };
    QualityMetrics checkQuality(const std::string& code);

private:
    // Clang tools
    std::unique_ptr<clang::ASTContext> ast_context_;
    std::unique_ptr<clang::DiagnosticsEngine> diagnostics_;
    
    // Analysis cache
    struct CacheEntry {
        Analysis analysis;
        std::time_t timestamp;
    };
    std::unordered_map<std::string, CacheEntry> analysis_cache_;
    
    // Pattern database
    struct Pattern {
        std::string name;
        std::string regex;
        std::string description;
        std::string replacement;
    };
    std::vector<Pattern> known_patterns_;
    
    // Helper methods
    void initClang();
    clang::ASTContext* parseCode(const std::string& code);
    std::vector<std::string> extractFunctions(clang::ASTContext* context);
    float calculateComplexity(const clang::FunctionDecl* func);
    bool isSecurityPattern(const std::string& pattern);
    void updatePatternDatabase();
};

} // namespace dev
} // namespace ghost
