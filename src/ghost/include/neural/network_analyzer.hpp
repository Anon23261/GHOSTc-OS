#pragma once

#include <string>
#include <vector>
#include <memory>
#include <tensorflow/lite/interpreter.h>

namespace ghost {
namespace neural {

class NetworkAnalyzer {
public:
    NetworkAnalyzer();
    ~NetworkAnalyzer();

    // Pattern analysis
    struct Pattern {
        std::string type;
        float confidence;
        std::vector<float> features;
        std::time_t timestamp;
    };
    
    std::vector<Pattern> analyzePatterns(const std::vector<float>& data);
    void learnPattern(const Pattern& pattern);
    
    // Model management
    void loadModel(const std::string& path);
    void saveModel(const std::string& path);
    void updateModel();
    
    // Training
    void train(const std::vector<std::pair<std::vector<float>, std::vector<float>>>& data);
    float evaluate(const std::vector<std::pair<std::vector<float>, std::vector<float>>>& test_data);

private:
    // TensorFlow components
    std::unique_ptr<tflite::Interpreter> interpreter_;
    std::vector<uint8_t> model_data_;
    
    // Neural state
    struct NeuralState {
        std::vector<Pattern> known_patterns;
        float learning_rate;
        size_t epochs_trained;
        float current_accuracy;
    };
    NeuralState state_;
    
    // Helper methods
    void initTensorFlow();
    void preprocessData(std::vector<float>& data);
    std::vector<float> extractFeatures(const std::vector<float>& data);
    void updateWeights(const std::vector<float>& gradients);
};

} // namespace neural
} // namespace ghost
