#pragma once

#include <string>
#include <memory>
#include <vector>
#include <random>
#include "neural_network.hpp"
#include "personality.hpp"
#include "memory.hpp"
#include "display.hpp"

namespace ghost {

class Ghost {
public:
    Ghost();
    ~Ghost();

    // Interaction methods
    std::string interact(const std::string& input);
    void update();
    void learn(const std::string& input, const std::string& response);
    
    // Emotional state
    struct EmotionalState {
        float happiness;
        float energy;
        float curiosity;
        float sociability;
    };

    // System status
    struct SystemStatus {
        float cpu_usage;
        float memory_usage;
        float battery_level;
        bool wifi_connected;
        std::string current_activity;
    };

private:
    // Core components
    std::unique_ptr<NeuralNetwork> brain_;
    std::unique_ptr<Personality> personality_;
    std::unique_ptr<Memory> memory_;
    std::unique_ptr<Display> display_;

    // State
    EmotionalState emotional_state_;
    SystemStatus system_status_;
    
    // Neural pathways
    struct Pathway {
        std::vector<float> weights;
        float strength;
        std::string category;
    };
    std::vector<Pathway> neural_pathways_;

    // Private methods
    void updateEmotionalState();
    void updateSystemStatus();
    void strengthenPathways(const std::string& category);
    std::string generateResponse(const std::vector<float>& thought_vector);
    
    // Random number generation
    std::random_device rd_;
    std::mt19937 gen_;
    std::uniform_real_distribution<> personality_variation_;
};

} // namespace ghost
