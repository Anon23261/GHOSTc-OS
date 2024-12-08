#!/bin/bash

set -e

# TensorFlow version
TENSORFLOW_VERSION="2.14.0"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Create third_party directory
mkdir -p "$PROJECT_ROOT/third_party"
cd "$PROJECT_ROOT/third_party"

# Clone TensorFlow if not exists
if [ ! -d "tensorflow" ]; then
    git clone --depth 1 --branch "v${TENSORFLOW_VERSION}" https://github.com/tensorflow/tensorflow.git
fi

cd tensorflow

# Download dependencies
./tensorflow/lite/tools/make/download_dependencies.sh

# Apply Raspberry Pi Zero W optimizations
sed -i 's/-O3/-O2/g' tensorflow/lite/tools/make/Makefile
sed -i 's/CXXFLAGS += -O3 -DNDEBUG/CXXFLAGS += -O2 -DNDEBUG -mcpu=arm1176jzf-s -mfpu=vfp -mfloat-abi=hard/g' tensorflow/lite/tools/make/Makefile

# Build TF Lite
make -j$(nproc) -f tensorflow/lite/tools/make/Makefile TARGET=rpi TARGET_ARCH=armv6 \
    EXTRA_CXXFLAGS="-march=armv6zk -mcpu=arm1176jzf-s -mfpu=vfp -mfloat-abi=hard" \
    EXTRA_CFLAGS="-march=armv6zk -mcpu=arm1176jzf-s -mfpu=vfp -mfloat-abi=hard"

# Create symbolic links
mkdir -p "$PROJECT_ROOT/third_party/tensorflow-lite/lib"
mkdir -p "$PROJECT_ROOT/third_party/tensorflow-lite/include"

cp tensorflow/lite/tools/make/gen/rpi_armv6/lib/libtensorflow-lite.a "$PROJECT_ROOT/third_party/tensorflow-lite/lib/"
cp -r tensorflow/lite/tools/make/downloads/flatbuffers/include/* "$PROJECT_ROOT/third_party/tensorflow-lite/include/"
cp -r tensorflow/lite/tools/make/downloads/absl/absl "$PROJECT_ROOT/third_party/tensorflow-lite/include/"
cp -r tensorflow/lite "$PROJECT_ROOT/third_party/tensorflow-lite/include/"

echo "TensorFlow Lite built successfully for Raspberry Pi Zero W"
