#pragma once

#include <string>
#include <memory>
#include <vector>
#include "epd2in13.h" // Waveshare e-paper display

namespace ghost {

class Display {
public:
    Display();
    ~Display();

    // Display operations
    void clear();
    void update();
    void showText(const std::string& text, int x, int y);
    void showEmotion(const std::string& emotion);
    
    // Drawing primitives
    void drawLine(int x0, int y0, int x1, int y1);
    void drawRect(int x, int y, int w, int h);
    void drawCircle(int x, int y, int r);
    
    // Animation
    void startAnimation(const std::string& animation_name);
    void stopAnimation();
    
    // Screen layouts
    void setLayout(const std::string& layout);
    void updateStatus(const std::string& status);

private:
    // E-paper display
    std::unique_ptr<Epd2in13> epd_;
    std::vector<unsigned char> frame_buffer_;
    
    // Animation state
    struct Animation {
        std::vector<std::vector<unsigned char>> frames;
        int current_frame;
        int frame_delay;
        bool loop;
    };
    std::unique_ptr<Animation> current_animation_;
    
    // Layout management
    struct Layout {
        std::vector<std::pair<int, int>> text_positions;
        std::vector<std::pair<int, int>> status_positions;
        std::string name;
    };
    std::vector<Layout> layouts_;
    Layout* current_layout_;

    // Helper methods
    void initDisplay();
    void loadAnimations();
    void loadLayouts();
    void updateBuffer();
    void renderFrame();
};

} // namespace ghost
