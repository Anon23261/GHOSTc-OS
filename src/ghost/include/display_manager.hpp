#pragma once

#include <memory>
#include <string>
#include <vector>
#include <SDL2/SDL.h>
#include "epd2in13.h" // Optional e-paper support

namespace ghost {

class DisplayManager {
public:
    DisplayManager();
    ~DisplayManager();

    enum class DisplayType {
        HDMI,
        EPAPER,
        NONE
    };

    struct DisplayConfig {
        int width;
        int height;
        int refresh_rate;
        DisplayType type;
        bool is_primary;
    };

    // Display initialization
    bool initDisplay();
    void detectDisplays();
    void setPreferredDisplay(DisplayType type);

    // Drawing operations
    void clear();
    void update();
    void render();
    
    // GUI elements
    void drawWindow(int x, int y, int w, int h, const std::string& title);
    void drawText(const std::string& text, int x, int y, SDL_Color color);
    void drawEmoji(const std::string& emotion, int x, int y);
    void drawProgressBar(int x, int y, int w, int h, float progress);
    
    // Animation system
    void startAnimation(const std::string& name);
    void stopAnimation();
    void updateAnimation();

    // Theme management
    void setTheme(const std::string& theme_name);
    void loadTheme(const std::string& theme_file);

private:
    // SDL components
    SDL_Window* window_;
    SDL_Renderer* renderer_;
    std::vector<SDL_Texture*> textures_;
    
    // Optional e-paper display
    std::unique_ptr<Epd2in13> epd_;
    bool has_epaper_;
    
    // Display state
    DisplayConfig current_display_;
    std::vector<DisplayConfig> available_displays_;
    
    // Theme data
    struct Theme {
        SDL_Color background;
        SDL_Color text;
        SDL_Color accent;
        std::string font;
        int font_size;
    };
    Theme current_theme_;
    
    // Animation data
    struct Animation {
        std::vector<SDL_Texture*> frames;
        int current_frame;
        int frame_delay;
        bool loop;
    };
    std::unique_ptr<Animation> current_animation_;

    // Helper methods
    bool initSDL();
    bool initEPaper();
    void cleanup();
    void loadAssets();
    SDL_Texture* loadTexture(const std::string& path);
    void renderHDMI();
    void renderEPaper();
};

} // namespace ghost
