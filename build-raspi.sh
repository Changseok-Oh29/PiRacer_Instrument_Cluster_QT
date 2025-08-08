#!/bin/bash

# Cross-compilation build script for Raspberry Pi 4 64-bit (ARM64)
# Make sure to install the cross-compilation toolchain first:
# sudo apt install gcc-aarch64-linux-gnu g++-aarch64-linux-gnu

# Configuration
BUILD_DIR="build-raspi"
PI_MODEL="4-64bit"  # Options: 4-64bit, 4-32bit, 3-32bit, 1-32bit, zero-32bit

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== Raspberry Pi Cross-Compilation Build Script ===${NC}"

# Check if cross-compiler is installed
if ! command -v aarch64-linux-gnu-gcc &> /dev/null; then
    echo -e "${RED}Error: ARM64 cross-compiler not found!${NC}"
    echo "Install it with: sudo apt install gcc-aarch64-linux-gnu g++-aarch64-linux-gnu"
    exit 1
fi

# Create build directory
echo -e "${YELLOW}Creating build directory...${NC}"
rm -rf $BUILD_DIR
mkdir $BUILD_DIR
cd $BUILD_DIR

# Configure CMake for cross-compilation
echo -e "${YELLOW}Configuring CMake for Raspberry Pi ${PI_MODEL}...${NC}"

# Update the toolchain file based on Pi model
case $PI_MODEL in
    "4-64bit")
        CPU_FLAGS="-mcpu=cortex-a72"
        echo -e "${GREEN}Building for Raspberry Pi 4 64-bit (ARM64)${NC}"
        ;;
    "4-32bit")
        CPU_FLAGS="-mcpu=cortex-a72 -mfpu=neon-fp-armv8 -mfloat-abi=hard"
        echo -e "${YELLOW}Warning: Using 32-bit mode, but your Pi is 64-bit capable${NC}"
        ;;
    "3-32bit")
        CPU_FLAGS="-mcpu=cortex-a53 -mfpu=neon-fp-armv8 -mfloat-abi=hard"
        ;;
    "1-32bit"|"zero-32bit")
        CPU_FLAGS="-mcpu=arm1176jzf-s -mfpu=vfp -mfloat-abi=hard"
        ;;
    *)
        echo -e "${RED}Unknown Pi model: $PI_MODEL${NC}"
        echo "Available options: 4-64bit, 4-32bit, 3-32bit, 1-32bit, zero-32bit"
        exit 1
        ;;
esac

# Run CMake configuration
cmake \
    -DCMAKE_TOOLCHAIN_FILE=../raspi-toolchain.cmake \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_C_FLAGS="$CPU_FLAGS" \
    -DCMAKE_CXX_FLAGS="$CPU_FLAGS" \
    ..

if [ $? -ne 0 ]; then
    echo -e "${RED}CMake configuration failed!${NC}"
    echo -e "${YELLOW}Make sure you have:${NC}"
    echo "1. Set up the Raspberry Pi sysroot in /home/jacob/sysroot"
    echo "2. Qt6 for Raspberry Pi in /home/jacob/sysroot/usr/lib/aarch64-linux-gnu/cmake"
    echo "3. Updated the paths in raspi-toolchain.cmake"
    exit 1
fi

# Build the project
echo -e "${YELLOW}Building project...${NC}"
cmake --build . -j$(nproc)

if [ $? -eq 0 ]; then
    echo -e "${GREEN}Build successful!${NC}"
    echo -e "${GREEN}Executable: $(pwd)/UntitledProjectApp${NC}"
    echo -e "${YELLOW}To deploy to Raspberry Pi:${NC}"
    scp UntitledProjectApp seame2025@192.168.86.75:/home/seame2025/
    scp ../rc_example.py seame2025@192.168.86.75:/home/seame2025/
    scp ../dbussender.py seame2025@192.168.86.75:/home/seame2025/
else
    echo -e "${RED}Build failed!${NC}"
    exit 1
fi
