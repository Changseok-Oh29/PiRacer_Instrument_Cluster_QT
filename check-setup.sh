#!/bin/bash

# Quick Cross-Compilation Setup Guide for Raspberry Pi 4 64-bit

echo "=== Raspberry Pi Cross-Compilation Setup ==="
echo ""

# Check if cross-compiler is installed
echo "1. Checking ARM64 cross-compiler..."
if command -v aarch64-linux-gnu-gcc &> /dev/null; then
    echo "   ✓ ARM64 cross-compiler found"
    aarch64-linux-gnu-gcc --version | head -1
else
    echo "   ✗ ARM64 cross-compiler not found"
    echo "   Install with: sudo apt install gcc-aarch64-linux-gnu g++-aarch64-linux-gnu"
    echo ""
fi

# Check sysroot
echo ""
echo "2. Checking Raspberry Pi sysroot..."
if [ -d "/opt/rpi/sysroot" ]; then
    echo "   ✓ Sysroot found at /opt/rpi/sysroot"
else
    echo "   ✗ Sysroot not found at /opt/rpi/sysroot"
    echo "   You need to create this from your Raspberry Pi"
    echo ""
    echo "   Quick setup:"
    echo "   sudo mkdir -p /opt/rpi/sysroot"
    echo "   rsync -avz pi@YOUR_PI_IP:/lib /opt/rpi/sysroot/"
    echo "   rsync -avz pi@YOUR_PI_IP:/usr/lib /opt/rpi/sysroot/usr/"
    echo "   rsync -avz pi@YOUR_PI_IP:/usr/include /opt/rpi/sysroot/usr/"
    echo ""
fi

# Check Qt6 for ARM64
echo ""
echo "3. Checking Qt6 for ARM64..."
if [ -d "/opt/rpi/qt6" ]; then
    echo "   ✓ Qt6 for Pi found at /opt/rpi/qt6"
else
    echo "   ✗ Qt6 for ARM64 not found at /opt/rpi/qt6"
    echo ""
    echo "   Options to get Qt6 for ARM64:"
    echo "   a) Download pre-compiled Qt6 for ARM64"
    echo "   b) Cross-compile Qt6 yourself"
    echo "   c) Copy from Raspberry Pi if Qt6 is installed there"
    echo ""
    echo "   For option c (if Qt6 is on your Pi):"
    echo "   rsync -avz pi@YOUR_PI_IP:/usr/lib/aarch64-linux-gnu/qt6 /opt/rpi/qt6"
    echo ""
fi

# Native build test
echo ""
echo "4. Testing native build..."
if [ -d "build-native" ]; then
    echo "   ✓ Native build directory exists"
    if [ -f "build-native/UntitledProjectApp" ]; then
        echo "   ✓ Native executable built successfully"
    else
        echo "   ? Native executable not found - try building:"
        echo "   cd build-native && cmake --build ."
    fi
else
    echo "   ? Native build not tested yet"
    echo "   Run: mkdir build-native && cd build-native"
    echo "   cmake -DCMAKE_PREFIX_PATH=/opt/Qt/6.8.3/gcc_64 .."
    echo "   cmake --build ."
fi

echo ""
echo "=== Next Steps ==="
echo ""
echo "For a quick cross-compilation test (may not run on Pi):"
echo "1. Install cross-compiler: sudo apt install gcc-aarch64-linux-gnu g++-aarch64-linux-gnu"
echo "2. Edit raspi-toolchain.cmake to use your host Qt6 temporarily"
echo "3. Run: ./build-raspi.sh"
echo ""
echo "For proper cross-compilation:"
echo "1. Set up sysroot from your Pi"
echo "2. Get Qt6 compiled for ARM64"
echo "3. Update paths in raspi-toolchain.cmake"
echo "4. Run: ./build-raspi.sh"
echo ""
