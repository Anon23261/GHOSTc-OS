#!/bin/bash

# GhostC Development Commands

# Build project
ghost-build() {
    echo "Building GhostOS..."
    ./tools/dev/build.sh $1
}

# Run tests
ghost-test() {
    echo "Running tests..."
    cd build && ctest --output-on-failure
}

# Deploy to Raspberry Pi
ghost-deploy() {
    local PI_IP=$1
    if [ -z "$PI_IP" ]; then
        echo "Usage: ghost-deploy <raspberry-pi-ip>"
        return 1
    fi
    echo "Deploying to Raspberry Pi at $PI_IP..."
    rsync -avz --progress build/bin/ "pi@$PI_IP:/usr/local/bin/"
}

# Start development environment
ghost-dev() {
    echo "Starting GhostOS development environment..."
    export GHOSTC_DEV=1
    export PATH="$PATH:$PWD/tools/dev"
    source scripts/dev-env.sh
}

# Security check
ghost-secure() {
    echo "Running security checks..."
    cppcheck --enable=all src/
    find src -name "*.cpp" -o -name "*.h" | xargs clang-tidy
}

# Clean build
ghost-clean() {
    echo "Cleaning build directory..."
    rm -rf build/*
}

# Update dependencies
ghost-update() {
    echo "Updating dependencies..."
    git submodule update --init --recursive
    ./scripts/setup-dev-environment.sh
}

# Create new component
ghost-create() {
    local component=$1
    if [ -z "$component" ]; then
        echo "Usage: ghost-create <component-name>"
        return 1
    fi
    echo "Creating new component: $component"
    mkdir -p "src/$component"
    mkdir -p "src/$component/include"
    mkdir -p "src/$component/src"
    mkdir -p "src/$component/test"
}

# Run in secure mode
ghost-secure-run() {
    echo "Running in secure mode..."
    GHOSTC_SECURE=1 GHOSTC_STEALTH=1 "$@"
}

# Profile performance
ghost-profile() {
    echo "Profiling performance..."
    perf record -g "$@"
    perf report
}

# Debug with GDB
ghost-debug() {
    echo "Starting debug session..."
    gdb --args "$@"
}

# Generate documentation
ghost-docs() {
    echo "Generating documentation..."
    doxygen docs/Doxyfile
}

# Setup IDE
ghost-ide() {
    echo "Setting up IDE..."
    cp -r config/ide/.vscode .
    code .
}

echo "GhostC development commands loaded. Use 'ghost-' commands to manage your development environment."
