#!/bin/bash

# Test script for UntitledProjectApp on Raspberry Pi
echo "=== UntitledProject App Test Script ==="

# Check if the executable exists
if [ ! -f "./UntitledProjectApp" ]; then
    echo "Error: UntitledProjectApp not found in current directory"
    echo "Make sure you're in the correct directory: /home/seame2025/"
    exit 1
fi

# Make sure it's executable
chmod +x ./UntitledProjectApp

# Check architecture
echo "Checking executable architecture:"
file ./UntitledProjectApp

# Check library dependencies
echo -e "\nChecking library dependencies:"
ldd ./UntitledProjectApp | head -10

# Set environment variables for Qt
export QML_IMPORT_PATH=/home/seame2025/qml:/usr/lib/aarch64-linux-gnu/qt6/qml:/usr/lib/qt6/qml
export QT_LOGGING_RULES="qt.qml.import.debug=true"
export QT_PLUGIN_PATH=/home/seame2025/qml

# Display information
echo -e "\nCurrent environment:"
echo "QML_IMPORT_PATH: $QML_IMPORT_PATH"
echo "DISPLAY: $DISPLAY"
echo "Current directory: $(pwd)"

# Try to run the application
echo -e "\n=== Attempting to run UntitledProjectApp ==="
echo "If you see QML import errors, try installing Qt6 QML modules:"
echo "sudo apt install qt6-declarative-dev qt6-quickcontrols2-dev"
echo ""

# Run with debug output
./UntitledProjectApp
