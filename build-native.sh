#!/bin/bash

# Native build script for testing on development machine
BUILD_DIR="build-native"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== Native Build Script (for development testing) ===${NC}"

# Create build directory
echo -e "${YELLOW}Creating build directory...${NC}"
rm -rf $BUILD_DIR
mkdir $BUILD_DIR
cd $BUILD_DIR

# Configure CMake for native build
echo -e "${YELLOW}Configuring CMake for native build...${NC}"

# Try to find Qt6 using multiple methods
QT6_FOUND=false

# Method 1: Check for Qt in /opt/Qt first
QT_OPT_PATH="/opt/Qt/6.4.2/gcc_64"
if [ -d "$QT_OPT_PATH" ]; then
    echo -e "${GREEN}Found Qt6 in /opt/Qt at: $QT_OPT_PATH${NC}"
    CMAKE_PREFIX_PATH="$QT_OPT_PATH/lib/cmake"
    QT6_FOUND=true
fi

# Method 2: Look for Qt6Config.cmake in standard locations
if [ "$QT6_FOUND" = false ]; then
    export Qt6_DIR=$(find /usr/lib/x86_64-linux-gnu/cmake /usr/local/lib/cmake /opt/Qt* -name "Qt6Config.cmake" -path "*/Qt6/*" 2>/dev/null | head -1 | dirname 2>/dev/null)
    if [ -n "$Qt6_DIR" ]; then
        echo -e "${GREEN}Found Qt6 at: $Qt6_DIR${NC}"
        CMAKE_PREFIX_PATH="$Qt6_DIR"
        QT6_FOUND=true
    fi
fi

# Method 3: Use pkg-config to find Qt6
if [ "$QT6_FOUND" = false ]; then
    if pkg-config --exists Qt6Core; then
        QT6_PREFIX=$(pkg-config --variable=prefix Qt6Core)
        echo -e "${GREEN}Found Qt6 via pkg-config at: $QT6_PREFIX${NC}"
        CMAKE_PREFIX_PATH="$QT6_PREFIX/lib/cmake"
        QT6_FOUND=true
    fi
fi

# Set up CMake configuration
if [ "$QT6_FOUND" = true ]; then
    cmake \
        -DCMAKE_BUILD_TYPE=Debug \
        -DCMAKE_PREFIX_PATH="$CMAKE_PREFIX_PATH" \
        ..
else
    echo -e "${YELLOW}Using system Qt6 detection...${NC}"
    cmake \
        -DCMAKE_BUILD_TYPE=Debug \
        ..
fi

if [ $? -ne 0 ]; then
    echo -e "${RED}CMake configuration failed!${NC}"
    echo -e "${YELLOW}Diagnostics:${NC}"
    echo "Qt6 Core found: $(pkg-config --exists Qt6Core && echo 'YES' || echo 'NO')"
    echo "Qt6 Qml found: $(pkg-config --exists Qt6Qml && echo 'YES' || echo 'NO')"
    echo "Qt6 Quick found: $(pkg-config --exists Qt6Quick && echo 'YES' || echo 'NO')"
    echo ""
    echo -e "${YELLOW}Try installing missing packages:${NC}"
    echo "sudo apt install qt6-base-dev qt6-declarative-dev qt6-declarative-dev-tools"
    echo ""
    echo -e "${YELLOW}CMake search paths:${NC}"
    echo "CMAKE_PREFIX_PATH: $CMAKE_PREFIX_PATH"
    echo "Qt6_DIR: $Qt6_DIR"
    exit 1
fi

# Build the project
echo -e "${YELLOW}Building project...${NC}"
cmake --build . -j$(nproc)

if [ $? -eq 0 ]; then
    echo -e "${GREEN}Native build successful!${NC}"
    echo -e "${GREEN}Executable: $(pwd)/UntitledProjectApp${NC}"
    echo -e "${YELLOW}To run locally:${NC}"
    echo "./UntitledProjectApp"
else
    echo -e "${RED}Build failed!${NC}"
    exit 1
fi
