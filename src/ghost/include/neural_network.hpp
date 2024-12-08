#pragma once

#include <vector>
#include <string>
#include <memory>
#include "tensorflow/lite/interpreter.h"

namespace ghost {

class NeuralNetwork {
public:
    NeuralNetwork();
    ~NeuralNetwork();

    struct Layer {
        std::vector<float> neurons;
        std::vector<std::vector<float>> weights;
        std::vector<float> biases;
    };

    // Neural network operations
    std::vector<float> process(const std::vector<float>& input);
    void train(const std::vector<std::pair<std::vector<float>, std::vector<float>>>& training_data);
    void save(const std::string& filename);
    void load(const std::string& filename);

    // Custom pathway management
    void createPathway(const std::string& category);
    void strengthenPathway(const std::string& category, float amount);
    float getPathwayStrength(const std::string& category) const;

private:
    // Network architecture
    std::vector<Layer> layers_;
    
    // TensorFlow Lite model for complex processing
    std::unique_ptr<tflite::Interpreter> interpreter_;
    
    // Activation functions
    float relu(float x);
    float sigmoid(float x);
    
    // Learning parameters
    float learning_rate_;
    float momentum_;
    
    // Pathway management
    struct PathwayInfo {
        std::vector<float> weights;
        float strength;
    };
    std::unordered_map<std::string, PathwayInfo> pathways_;
    
    // Helper methods
    void backpropagate(const std::vector<float>& error);
    std::vector<float> forwardPass(const std::vector<float>& input);
    void updateWeights(const std::vector<std::vector<float>>& gradients);
};

} // namespace ghost
