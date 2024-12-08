#pragma once

#include <string>
#include <vector>
#include <memory>
#include <filesystem>
#include "neural_network.hpp"
#include "code_analyzer.hpp"
#include "project_manager.hpp"

namespace ghost {
namespace dev {

class DevAssistant {
public:
    DevAssistant();
    ~DevAssistant();

    // Code assistance
    std::string getCodeCompletion(const std::string& code, size_t cursor_pos);
    std::vector<std::string> getSuggestions(const std::string& context);
    std::string explainCode(const std::string& code);
    
    // Project management
    void createProject(const std::string& name, const std::string& type);
    void buildProject(const std::string& path);
    void runTests(const std::string& path);
    
    // Documentation
    void generateDocs(const std::string& path);
    std::string searchDocs(const std::string& query);
    
    // Debugging
    struct DebugInfo {
        std::string variable;
        std::string value;
        std::string type;
        std::string scope;
    };
    std::vector<DebugInfo> analyzeDebugOutput(const std::string& output);
    std::string suggestFix(const std::string& error);
    
    // Version control
    void initRepo(const std::string& path);
    void commitChanges(const std::string& message);
    void createBranch(const std::string& name);
    
    // Learning
    void learnFromCode(const std::string& code);
    void updateCodeModel(const std::string& feedback);

private:
    // Components
    std::unique_ptr<CodeAnalyzer> analyzer_;
    std::unique_ptr<ProjectManager> project_manager_;
    std::unique_ptr<NeuralNetwork> code_model_;
    
    // Language support
    struct Language {
        std::string name;
        std::vector<std::string> file_extensions;
        std::vector<std::string> keywords;
        std::string compiler;
        std::string build_system;
    };
    std::vector<Language> supported_languages_;
    
    // Project templates
    struct Template {
        std::string name;
        std::string language;
        std::filesystem::path template_path;
        std::vector<std::string> required_tools;
    };
    std::vector<Template> project_templates_;
    
    // Helper methods
    Language detectLanguage(const std::string& file_path);
    std::vector<std::string> parseCode(const std::string& code);
    std::string generateBuildCommands(const std::string& project_type);
    void setupDevEnvironment(const Language& lang);
};

} // namespace dev
} // namespace ghost
