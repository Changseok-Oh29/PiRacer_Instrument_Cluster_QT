#!/bin/bash

# Static Build Deployment Script for Raspberry Pi
echo "=== Deploying Static Build to Raspberry Pi ==="

PI_USER="seame2025"
PI_HOST="seameteam7"
PI_HOME="/home/seame2025"

# Copy the self-contained executable
echo "Copying static executable..."
scp build-raspi/UntitledProjectApp ${PI_USER}@${PI_HOST}:${PI_HOME}/

# Make it executable
ssh ${PI_USER}@${PI_HOST} "chmod +x ${PI_HOME}/UntitledProjectApp"

echo "=== Static Deployment Complete ==="
echo ""
echo "The application is now ready to run on Raspberry Pi!"
echo "All QML modules and assets are embedded in the executable."
echo ""
echo "To run:"
echo "ssh ${PI_USER}@${PI_HOST}"
echo "cd ${PI_HOME}"
echo "./UntitledProjectApp"
echo ""
echo "If you have display issues, try:"
echo "QT_QPA_PLATFORM=eglfs ./UntitledProjectApp    # For fullscreen"
echo "QT_QPA_PLATFORM=xcb ./UntitledProjectApp      # For windowed mode"
