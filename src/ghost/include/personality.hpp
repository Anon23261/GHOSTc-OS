#pragma once

#include <string>
#include <vector>
#include <map>
#include <random>

namespace ghost {

class Personality {
public:
    Personality();
    ~Personality();

    struct Trait {
        float baseline;
        float current;
        float volatility;
        float adaptability;
    };

    struct Emotion {
        float intensity;
        float duration;
        float decay_rate;
    };

    // Personality management
    void update();
    void evolve(const std::string& stimulus, float intensity);
    std::string getCurrentMood() const;
    
    // Emotional responses
    void processEmotion(const std::string& emotion_type, float intensity);
    float getEmotionalResponse(const std::string& situation) const;
    
    // Personality traits
    float getTraitValue(const std::string& trait) const;
    void adjustTrait(const std::string& trait, float amount);

private:
    // Core personality traits
    std::map<std::string, Trait> traits_ = {
        {"openness", {0.7f, 0.7f, 0.1f, 0.3f}},
        {"curiosity", {0.8f, 0.8f, 0.2f, 0.4f}},
        {"friendliness", {0.6f, 0.6f, 0.15f, 0.3f}},
        {"adaptability", {0.75f, 0.75f, 0.1f, 0.5f}}
    };

    // Emotional state
    std::map<std::string, Emotion> emotions_;
    
    // Memory influence
    struct MemoryInfluence {
        std::string event;
        float impact;
        float decay_rate;
    };
    std::vector<MemoryInfluence> memory_influences_;

    // Helper methods
    void updateTraits();
    void decayEmotions();
    void processMemoryInfluences();
    
    // Random variations
    std::random_device rd_;
    std::mt19937 gen_;
    std::normal_distribution<> personality_variation_;
};

} // namespace ghost
