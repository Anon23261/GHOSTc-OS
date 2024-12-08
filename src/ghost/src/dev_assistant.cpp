#include "dev_assistant.hpp"
#include <iostream>
#include <fstream>
#include <sstream>

namespace ghost {
namespace dev {

DevAssistant::DevAssistant() {
    // Initialize components
    analyzer_ = std::make_unique<CodeAnalyzer>();
    project_manager_ = std::make_unique<ProjectManager>();
    code_model_ = std::make_unique<NeuralNetwork>();
    
    // Set up supported languages
    supported_languages_ = {
        {"C++", {".cpp", ".hpp", ".h"}, {"auto", "class", "const"}, "g++", "cmake"},
        {"Python", {".py"}, {"def", "class", "import"}, "python3", "pip"},
        {"Rust", {".rs"}, {"fn", "let", "use"}, "rustc", "cargo"},
        {"Go", {".go"}, {"func", "var", "import"}, "go", "go build"},
    };
    
    // Set up project templates
    project_templates_ = {
        {"cpp-lib", "C++", "/opt/ghost/templates/cpp-lib", {"cmake", "g++", "make"}},
        {"cpp-app", "C++", "/opt/ghost/templates/cpp-app", {"cmake", "g++", "make"}},
        {"python-pkg", "Python", "/opt/ghost/templates/python-pkg", {"python3", "pip"}},
        {"rust-lib", "Rust", "/opt/ghost/templates/rust-lib", {"cargo"}},
    };
}

std::string DevAssistant::getCodeCompletion(const std::string& code, size_t cursor_pos) {
    // Get context around cursor
    std::string context = code.substr(0, cursor_pos);
    
    // Analyze context
    auto analysis = analyzer_->analyzeCode(context);
    
    // Generate completion using neural network
    std::vector<float> context_vector = code_model_->process(
        std::vector<float>(context.begin(), context.end())
    );
    
    // Convert back to code suggestion
    std::string completion;
    for (float f : context_vector) {
        completion += static_cast<char>(f * 255);
    }
    
    return completion;
}

void DevAssistant::createProject(const std::string& name, const std::string& type) {
    // Find matching template
    auto it = std::find_if(project_templates_.begin(), project_templates_.end(),
        [&](const Template& t) { return t.name == type; });
    
    if (it == project_templates_.end()) {
        throw std::runtime_error("Unknown project type: " + type);
    }
    
    // Create project using template
    project_manager_->createProject(name, type);
    
    // Setup development environment
    auto lang = std::find_if(supported_languages_.begin(), supported_languages_.end(),
        [&](const Language& l) { return l.name == it->language; });
    
    if (lang != supported_languages_.end()) {
        setupDevEnvironment(*lang);
    }
}

void DevAssistant::learnFromCode(const std::string& code) {
    // Analyze code for patterns
    auto patterns = analyzer_->findPatterns(code);
    
    // Update neural network with new patterns
    for (const auto& pattern : patterns) {
        std::vector<float> pattern_vector(pattern.begin(), pattern.end());
        code_model_->train({{pattern_vector, pattern_vector}});
    }
}

void DevAssistant::setupDevEnvironment(const Language& lang) {
    // Create build system configuration
    ProjectManager::BuildConfig config;
    config.compiler = lang.compiler;
    config.flags = "-Wall -Wextra -O2";  // Default flags
    
    // Set up build system
    project_manager_->setBuildConfig(config);
    
    // Initialize version control
    project_manager_->getGitStatus();  // This will create a repo if none exists
}

DevAssistant::~DevAssistant() = default;

} // namespace dev
} // namespace ghost
