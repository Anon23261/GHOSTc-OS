#pragma once

#include <string>
#include <vector>
#include <memory>
#include <functional>

namespace ghost {
namespace terminal {

class Terminal {
public:
    Terminal();
    ~Terminal();

    // Terminal configuration
    struct Config {
        int rows;
        int cols;
        std::string font_family;
        int font_size;
        std::string color_scheme;
        bool transparency;
        float opacity;
    };

    // Terminal features
    void initialize(const Config& config);
    void resize(int rows, int cols);
    void setFont(const std::string& family, int size);
    void setColorScheme(const std::string& scheme);
    void setTransparency(bool enable, float opacity);

    // Input/Output
    void write(const std::string& text);
    void writeLine(const std::string& text);
    std::string readLine();
    char readChar();

    // Shell integration
    void executeCommand(const std::string& command);
    void setShell(const std::string& shell_path);
    void registerShortcut(const std::string& key, std::function<void()> callback);

    // Tab management
    void newTab();
    void closeTab(int index);
    void switchTab(int index);
    
    // Split screen
    void splitVertical();
    void splitHorizontal();
    void focusPane(int index);

    // Customization
    void loadTheme(const std::string& theme_file);
    void setCustomColors(const std::vector<std::string>& colors);
    void setCustomFont(const std::string& font_path);

private:
    struct TerminalState {
        Config config;
        std::string current_dir;
        std::vector<std::string> history;
        bool is_running;
    };
    TerminalState state_;

    // Internal methods
    void setupPty();
    void handleInput();
    void updateScreen();
    void processEscapeSequences();
};

} // namespace terminal
} // namespace ghost
