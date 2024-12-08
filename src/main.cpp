#include <iostream>
#include <thread>
#include <chrono>
#include <signal.h>
#include "ghost.hpp"

// Global flag for graceful shutdown
volatile sig_atomic_t running = 1;

// Signal handler
void signal_handler(int signal) {
    running = 0;
}

int main() {
    // Set up signal handling
    signal(SIGINT, signal_handler);
    signal(SIGTERM, signal_handler);

    std::cout << "Starting GhostOS AI Assistant..." << std::endl;

    try {
        // Initialize Ghost AI
        ghost::Ghost ghost;
        
        // Main loop
        while (running) {
            // Update Ghost's state
            ghost.update();

            // Process any input (could be from various sources)
            std::string input;
            if (std::getline(std::cin, input)) {
                if (!input.empty()) {
                    // Get response from Ghost
                    std::string response = ghost.interact(input);
                    std::cout << "Ghost: " << response << std::endl;

                    // Let Ghost learn from the interaction
                    ghost.learn(input, response);
                }
            }

            // Small sleep to prevent CPU hogging
            std::this_thread::sleep_for(std::chrono::milliseconds(100));
        }

        std::cout << "Shutting down GhostOS gracefully..." << std::endl;
        return 0;

    } catch (const std::exception& e) {
        std::cerr << "Fatal error: " << e.what() << std::endl;
        return 1;
    }
}
