#pragma once

#include <string>
#include <vector>
#include <memory>
#include <filesystem>
#include <future>

namespace ghost {
namespace dev {

class ProjectManager {
public:
    ProjectManager();
    ~ProjectManager();

    // Project management
    void createProject(const std::string& name, const std::string& type);
    void openProject(const std::string& path);
    void closeProject();
    
    // Build system
    struct BuildConfig {
        std::string compiler;
        std::string flags;
        std::vector<std::string> dependencies;
        std::string output_dir;
    };
    
    void setBuildConfig(const BuildConfig& config);
    bool build();
    bool clean();
    bool rebuild();
    
    // Testing
    struct TestResult {
        std::string name;
        bool passed;
        std::string output;
        std::string error;
        double duration;
    };
    
    std::vector<TestResult> runTests();
    std::vector<TestResult> runTest(const std::string& test_name);
    void generateTestReport();
    
    // Dependencies
    void addDependency(const std::string& name, const std::string& version);
    void removeDependency(const std::string& name);
    void updateDependencies();
    
    // Version control
    struct GitStatus {
        std::vector<std::string> modified;
        std::vector<std::string> added;
        std::vector<std::string> deleted;
        std::string current_branch;
    };
    
    GitStatus getGitStatus();
    void commit(const std::string& message);
    void push();
    void pull();
    
    // Project analysis
    struct ProjectStats {
        size_t total_files;
        size_t total_lines;
        size_t code_lines;
        size_t comment_lines;
        std::unordered_map<std::string, size_t> language_breakdown;
    };
    
    ProjectStats getProjectStats();
    std::vector<std::string> findTODOs();
    std::vector<std::string> generateChangeLog();

private:
    // Project state
    struct Project {
        std::string name;
        std::string type;
        std::filesystem::path root_path;
        BuildConfig build_config;
        bool is_open;
    };
    std::unique_ptr<Project> current_project_;
    
    // Build system
    struct BuildSystem {
        std::string name;
        std::string config_file;
        std::vector<std::string> build_commands;
    };
    std::unordered_map<std::string, BuildSystem> build_systems_;
    
    // Async operations
    std::future<bool> current_build_;
    std::future<std::vector<TestResult>> current_tests_;
    
    // Helper methods
    void setupBuildSystem(const std::string& type);
    void generateBuildFiles();
    bool validateDependencies();
    void setupGitRepo();
    void loadProjectConfig();
    void saveProjectConfig();
};

} // namespace dev
} // namespace ghost
