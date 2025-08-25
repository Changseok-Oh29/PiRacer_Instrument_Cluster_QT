#!/bin/bash

# QML Plugin Deployment Script for Raspberry Pi
echo "=== Deploying QML Plugins to Raspberry Pi ==="

PI_USER="seame2025"
PI_HOST="seameteam7"
PI_HOME="/home/seame2025"

# Create QML module directories on Pi
echo "Creating QML module directories..."
ssh ${PI_USER}@${PI_HOST} "mkdir -p ${PI_HOME}/qml/content ${PI_HOME}/qml/UntitledProject"

# Copy plugin libraries and qmldir files
echo "Copying content module..."
scp build-raspi/content/libcontentplugin.so ${PI_USER}@${PI_HOST}:${PI_HOME}/qml/content/
scp build-raspi/content/qmldir ${PI_USER}@${PI_HOST}:${PI_HOME}/qml/content/

echo "Copying UntitledProject module..."
scp build-raspi/imports/UntitledProject/libUntitledProjectplugin.so ${PI_USER}@${PI_HOST}:${PI_HOME}/qml/UntitledProject/
scp build-raspi/imports/UntitledProject/qmldir ${PI_USER}@${PI_HOST}:${PI_HOME}/qml/UntitledProject/

# Also copy the type info files if they exist
if [ -f "build-raspi/content/contentplugin.qmltypes" ]; then
    echo "Copying content qmltypes..."
    scp build-raspi/content/contentplugin.qmltypes ${PI_USER}@${PI_HOST}:${PI_HOME}/qml/content/
fi

if [ -f "build-raspi/imports/UntitledProject/UntitledProjectplugin.qmltypes" ]; then
    echo "Copying UntitledProject qmltypes..."
    scp build-raspi/imports/UntitledProject/UntitledProjectplugin.qmltypes ${PI_USER}@${PI_HOST}:${PI_HOME}/qml/UntitledProject/
fi

echo "=== Deployment Complete ==="
echo "QML modules deployed to: ${PI_HOME}/qml/"
echo ""
echo "To run the application with the QML modules:"
echo "ssh ${PI_USER}@${PI_HOST}"
echo "export QML_IMPORT_PATH=${PI_HOME}/qml"
echo "cd ${PI_HOME}"
echo "./UntitledProjectApp"
