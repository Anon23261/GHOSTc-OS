#include "display_manager.hpp"
#include <stdexcept>
#include <iostream>

namespace ghost {

DisplayManager::DisplayManager() 
    : window_(nullptr)
    , renderer_(nullptr)
    , has_epaper_(false) {
    if (!initDisplay()) {
        throw std::runtime_error("Failed to initialize display system");
    }
}

DisplayManager::~DisplayManager() {
    cleanup();
}

bool DisplayManager::initDisplay() {
    // Initialize SDL
    if (!initSDL()) {
        std::cerr << "Failed to initialize SDL" << std::endl;
        return false;
    }

    // Detect available displays
    detectDisplays();

    // Try to initialize e-paper display
    try {
        if (initEPaper()) {
            has_epaper_ = true;
            std::cout << "E-paper display initialized" << std::endl;
        }
    } catch (const std::exception& e) {
        std::cout << "E-paper display not available: " << e.what() << std::endl;
    }

    // Create window and renderer
    window_ = SDL_CreateWindow(
        "Ghost AI",
        SDL_WINDOWPOS_CENTERED,
        SDL_WINDOWPOS_CENTERED,
        800, // Default width
        480, // Default height
        SDL_WINDOW_SHOWN | SDL_WINDOW_RESIZABLE
    );

    if (!window_) {
        std::cerr << "Failed to create window: " << SDL_GetError() << std::endl;
        return false;
    }

    renderer_ = SDL_CreateRenderer(
        window_,
        -1,
        SDL_RENDERER_ACCELERATED | SDL_RENDERER_PRESENTVSYNC
    );

    if (!renderer_) {
        std::cerr << "Failed to create renderer: " << SDL_GetError() << std::endl;
        return false;
    }

    // Load assets and theme
    loadAssets();
    setTheme("default");

    return true;
}

void DisplayManager::update() {
    // Update animations
    updateAnimation();

    // Clear screen
    SDL_SetRenderDrawColor(renderer_, 
        current_theme_.background.r,
        current_theme_.background.g,
        current_theme_.background.b,
        current_theme_.background.a);
    SDL_RenderClear(renderer_);

    // Render current frame
    render();

    // Update screen
    SDL_RenderPresent(renderer_);

    // Update e-paper if available
    if (has_epaper_) {
        renderEPaper();
    }
}

void DisplayManager::drawText(const std::string& text, int x, int y, SDL_Color color) {
    // Implementation using SDL_ttf
    // (Add actual text rendering code here)
}

void DisplayManager::drawEmoji(const std::string& emotion, int x, int y) {
    // Find and render the appropriate emotion texture
    // (Add actual emoji rendering code here)
}

void DisplayManager::setTheme(const std::string& theme_name) {
    // Load theme data
    // (Add actual theme loading code here)
}

bool DisplayManager::initSDL() {
    if (SDL_Init(SDL_INIT_VIDEO | SDL_INIT_EVENTS) < 0) {
        std::cerr << "SDL initialization failed: " << SDL_GetError() << std::endl;
        return false;
    }
    return true;
}

bool DisplayManager::initEPaper() {
    // Only try to initialize if the hardware is present
    // Return false if not available or initialization fails
    return false;
}

void DisplayManager::cleanup() {
    // Cleanup SDL resources
    for (auto texture : textures_) {
        SDL_DestroyTexture(texture);
    }
    textures_.clear();

    if (renderer_) {
        SDL_DestroyRenderer(renderer_);
        renderer_ = nullptr;
    }

    if (window_) {
        SDL_DestroyWindow(window_);
        window_ = nullptr;
    }

    SDL_Quit();
}

void DisplayManager::detectDisplays() {
    available_displays_.clear();
    
    // Get number of displays
    int display_count = SDL_GetNumVideoDisplays();
    
    for (int i = 0; i < display_count; ++i) {
        SDL_DisplayMode mode;
        if (SDL_GetCurrentDisplayMode(i, &mode) == 0) {
            DisplayConfig config;
            config.width = mode.w;
            config.height = mode.h;
            config.refresh_rate = mode.refresh_rate;
            config.type = DisplayType::HDMI;
            config.is_primary = (i == 0);
            available_displays_.push_back(config);
        }
    }
}

} // namespace ghost
