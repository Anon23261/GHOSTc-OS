#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <signal.h>
#include <sys/types.h>
#include <sys/stat.h>
#include "../include/ghostc.h"

// Neural network configuration
#define NN_INPUT_SIZE 784    // 28x28 input
#define NN_HIDDEN_SIZE 128   // Hidden layer size
#define NN_OUTPUT_SIZE 10    // Output classes

// Neural network parameters
static float *input_weights;
static float *hidden_weights;
static float *input_layer;
static float *hidden_layer;
static float *output_layer;

// Initialize neural network
static int init_network(void) {
    // Allocate memory for network layers
    input_weights = calloc(NN_INPUT_SIZE * NN_HIDDEN_SIZE, sizeof(float));
    hidden_weights = calloc(NN_HIDDEN_SIZE * NN_OUTPUT_SIZE, sizeof(float));
    input_layer = calloc(NN_INPUT_SIZE, sizeof(float));
    hidden_layer = calloc(NN_HIDDEN_SIZE, sizeof(float));
    output_layer = calloc(NN_OUTPUT_SIZE, sizeof(float));

    if (!input_weights || !hidden_weights || !input_layer || 
        !hidden_layer || !output_layer) {
        fprintf(stderr, "Failed to allocate neural network memory\n");
        return -1;
    }

    // Load pre-trained weights if available
    FILE *f = fopen("/usr/local/lib/ghostc/nn_weights.bin", "rb");
    if (f) {
        fread(input_weights, sizeof(float), NN_INPUT_SIZE * NN_HIDDEN_SIZE, f);
        fread(hidden_weights, sizeof(float), NN_HIDDEN_SIZE * NN_OUTPUT_SIZE, f);
        fclose(f);
    } else {
        // Initialize with random weights if no pre-trained weights
        for (int i = 0; i < NN_INPUT_SIZE * NN_HIDDEN_SIZE; i++)
            input_weights[i] = ((float)rand() / RAND_MAX) * 2.0f - 1.0f;
        for (int i = 0; i < NN_HIDDEN_SIZE * NN_OUTPUT_SIZE; i++)
            hidden_weights[i] = ((float)rand() / RAND_MAX) * 2.0f - 1.0f;
    }

    return 0;
}

// ReLU activation function
static float relu(float x) {
    return x > 0 ? x : 0;
}

// Forward pass through the network
static void forward_pass(const uint8_t *input) {
    // Input layer
    for (int i = 0; i < NN_INPUT_SIZE; i++)
        input_layer[i] = input[i] / 255.0f;  // Normalize input

    // Hidden layer
    for (int i = 0; i < NN_HIDDEN_SIZE; i++) {
        float sum = 0;
        for (int j = 0; j < NN_INPUT_SIZE; j++)
            sum += input_layer[j] * input_weights[j * NN_HIDDEN_SIZE + i];
        hidden_layer[i] = relu(sum);
    }

    // Output layer
    for (int i = 0; i < NN_OUTPUT_SIZE; i++) {
        float sum = 0;
        for (int j = 0; j < NN_HIDDEN_SIZE; j++)
            sum += hidden_layer[j] * hidden_weights[j * NN_OUTPUT_SIZE + i];
        output_layer[i] = relu(sum);
    }
}

// Process input data
static int process_data(const char *input_file) {
    FILE *f = fopen(input_file, "rb");
    if (!f) {
        fprintf(stderr, "Failed to open input file: %s\n", input_file);
        return -1;
    }

    uint8_t input_data[NN_INPUT_SIZE];
    size_t read_size = fread(input_data, 1, NN_INPUT_SIZE, f);
    fclose(f);

    if (read_size != NN_INPUT_SIZE) {
        fprintf(stderr, "Invalid input data size\n");
        return -1;
    }

    forward_pass(input_data);

    // Find highest probability output
    float max_prob = output_layer[0];
    int max_index = 0;
    for (int i = 1; i < NN_OUTPUT_SIZE; i++) {
        if (output_layer[i] > max_prob) {
            max_prob = output_layer[i];
            max_index = i;
        }
    }

    printf("Classification result: %d (confidence: %.2f%%)\n", 
           max_index, max_prob * 100.0f);

    return 0;
}

// Cleanup
static void cleanup(void) {
    free(input_weights);
    free(hidden_weights);
    free(input_layer);
    free(hidden_layer);
    free(output_layer);
}

int main(int argc, char *argv[]) {
    if (argc != 2) {
        fprintf(stderr, "Usage: %s <input_file>\n", argv[0]);
        return 1;
    }

    if (init_network() < 0) {
        fprintf(stderr, "Failed to initialize neural network\n");
        return 1;
    }

    int ret = process_data(argv[1]);
    cleanup();
    return ret;
}
