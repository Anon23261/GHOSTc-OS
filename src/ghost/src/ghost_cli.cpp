#include <iostream>
#include <string>
#include <vector>
#include <sstream>
#include <cxxopts.hpp>
#include "ghost.hpp"
#include "dev_assistant.hpp"

using namespace ghost;

// Command handlers
void handleHelp(dev::DevAssistant& assistant, const std::string& query) {
    std::cout << "Ghost: Let me help you with that...\n";
    auto suggestions = assistant.getSuggestions(query);
    for (const auto& suggestion : suggestions) {
        std::cout << suggestion << "\n";
    }
}

void handleAnalyze(dev::DevAssistant& assistant, const std::string& file) {
    std::cout << "Ghost: Analyzing " << file << "...\n";
    std::ifstream code_file(file);
    std::stringstream buffer;
    buffer << code_file.rdbuf();
    
    auto analysis = assistant.explainCode(buffer.str());
    std::cout << analysis << "\n";
}

void handleBuild(dev::DevAssistant& assistant) {
    std::cout << "Ghost: Building project...\n";
    assistant.buildProject(".");
}

void handleDoc(dev::DevAssistant& assistant, const std::string& path) {
    std::cout << "Ghost: Generating documentation...\n";
    assistant.generateDocs(path);
}

int main(int argc, char* argv[]) {
    try {
        // Parse command line options
        cxxopts::Options options("ghost", "Ghost AI Development Assistant");
        options.add_options()
            ("h,help", "Show help")
            ("command", "Command to execute", cxxopts::value<std::string>())
            ("args", "Command arguments", cxxopts::value<std::vector<std::string>>());
        
        options.parse_positional({"command", "args"});
        auto result = options.parse(argc, argv);

        // Initialize Ghost AI
        Ghost ghost;
        dev::DevAssistant assistant;

        // Handle commands
        if (result.count("command")) {
            std::string command = result["command"].as<std::string>();
            auto args = result.count("args") ? 
                result["args"].as<std::vector<std::string>>() : 
                std::vector<std::string>();

            if (command == "help" && !args.empty()) {
                handleHelp(assistant, args[0]);
            }
            else if (command == "analyze" && !args.empty()) {
                handleAnalyze(assistant, args[0]);
            }
            else if (command == "build") {
                handleBuild(assistant);
            }
            else if (command == "doc" && !args.empty()) {
                handleDoc(assistant, args[0]);
            }
            else {
                std::cout << "Unknown command: " << command << "\n";
                return 1;
            }
        }
        else {
            std::cout << options.help() << "\n";
            return 0;
        }

    } catch (const std::exception& e) {
        std::cerr << "Error: " << e.what() << "\n";
        return 1;
    }

    return 0;
}
