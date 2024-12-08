#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
BUILD_DIR="$PROJECT_ROOT/build"
THIRD_PARTY="$PROJECT_ROOT/third_party"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}Setting up GhostOS Development Environment${NC}"

# Create directories
mkdir -p "$BUILD_DIR"
mkdir -p "$THIRD_PARTY"

# Install development tools
echo -e "${GREEN}Installing development dependencies...${NC}"
sudo apt-get update
sudo apt-get install -y \
    cmake ninja-build ccache \
    python3-dev python3-pip \
    libboost-all-dev \
    libssl-dev \
    libsqlite3-dev \
    libncurses5-dev \
    libreadline-dev \
    zlib1g-dev \
    libbz2-dev \
    libffi-dev \
    liblzma-dev

# Setup Python environment
echo -e "${GREEN}Setting up Python environment...${NC}"
python3 -m pip install --user --upgrade pip
python3 -m pip install --user \
    numpy \
    setuptools \
    wheel \
    pybind11 \
    six \
    future \
    packaging \
    requests

# Clone and build TensorFlow
echo -e "${GREEN}Building TensorFlow for ARM...${NC}"
cd "$THIRD_PARTY"

if [ ! -d "tensorflow" ]; then
    git clone --depth 1 --branch v2.14.0 https://github.com/tensorflow/tensorflow.git
fi

cd tensorflow

# Configure TensorFlow build
echo -e "${BLUE}Configuring TensorFlow...${NC}"
./configure

# Apply ARM optimizations
echo -e "${GREEN}Applying ARM optimizations...${NC}"
cat > arm_optimization.patch << 'EOF'
diff --git a/tensorflow/lite/tools/make/Makefile b/tensorflow/lite/tools/make/Makefile
index a1b2c3f..d4e5f6g 100644
--- a/tensorflow/lite/tools/make/Makefile
+++ b/tensorflow/lite/tools/make/Makefile
@@ -35,7 +35,7 @@ endif
 
 # Optimization flags
 OPTFLAGS := -O3 -DNDEBUG
-ifeq ($(TARGET_ARCH),armv6)
+ifeq ($(TARGET_ARCH),armv6l)
   OPTFLAGS += -mfpu=vfp -mfloat-abi=hard -mcpu=arm1176jzf-s
   EXTRA_CFLAGS += -march=armv6zk
   EXTRA_CXXFLAGS += -march=armv6zk
EOF

patch -p1 < arm_optimization.patch

# Build TensorFlow Lite
echo -e "${GREEN}Building TensorFlow Lite...${NC}"
make -j$(nproc) -f tensorflow/lite/tools/make/Makefile TARGET=rpi TARGET_ARCH=armv6l

# Setup development environment
echo -e "${GREEN}Setting up development environment...${NC}"
cd "$PROJECT_ROOT"

# Create VSCode configuration
mkdir -p .vscode
cat > .vscode/settings.json << 'EOF'
{
    "cmake.configureArgs": [
        "-DCMAKE_BUILD_TYPE=Debug",
        "-DCMAKE_TOOLCHAIN_FILE=cmake/arm-linux-gnueabihf.cmake",
        "-DCMAKE_EXPORT_COMPILE_COMMANDS=ON"
    ],
    "cmake.buildDirectory": "${workspaceFolder}/build",
    "cmake.parallelJobs": 4,
    "files.associations": {
        "*.h": "cpp",
        "*.hpp": "cpp",
        "*.cpp": "cpp"
    },
    "editor.formatOnSave": true,
    "C_Cpp.default.configurationProvider": "ms-vscode.cmake-tools"
}
EOF

# Create ARM toolchain file
mkdir -p cmake
cat > cmake/arm-linux-gnueabihf.cmake << 'EOF'
set(CMAKE_SYSTEM_NAME Linux)
set(CMAKE_SYSTEM_PROCESSOR arm)

set(CMAKE_C_COMPILER arm-linux-gnueabihf-gcc)
set(CMAKE_CXX_COMPILER arm-linux-gnueabihf-g++)

set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)

set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -mcpu=arm1176jzf-s -mfpu=vfp -mfloat-abi=hard -O2")
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -mcpu=arm1176jzf-s -mfpu=vfp -mfloat-abi=hard -O2")
EOF

# Create development tools directory
mkdir -p tools/dev
cat > tools/dev/build.sh << 'EOF'
#!/bin/bash
set -e

BUILD_TYPE=${1:-Debug}
mkdir -p build
cd build
cmake .. -DCMAKE_BUILD_TYPE=$BUILD_TYPE -GNinja
ninja -j$(nproc)
EOF
chmod +x tools/dev/build.sh

# Setup Git hooks
mkdir -p .git/hooks
cat > .git/hooks/pre-commit << 'EOF'
#!/bin/bash
set -e

# Run clang-format
git diff --cached --name-only --diff-filter=ACMR | grep -E "\.(cpp|h|hpp)$" | \
    xargs -n1 clang-format -i -style=file

# Run security checks
git diff --cached --name-only --diff-filter=ACMR | while read file; do
    if [[ "$file" =~ \.(cpp|h|hpp)$ ]]; then
        cppcheck --enable=all --suppress=missingIncludeSystem "$file"
    fi
done
EOF
chmod +x .git/hooks/pre-commit

echo -e "${GREEN}Development environment setup complete!${NC}"
echo -e "${BLUE}Next steps:${NC}"
echo "1. Use 'tools/dev/build.sh' to build the project"
echo "2. Find TensorFlow Lite libraries in third_party/tensorflow"
echo "3. Use VSCode with the provided configuration"
echo "4. Run security checks with pre-commit hooks"
