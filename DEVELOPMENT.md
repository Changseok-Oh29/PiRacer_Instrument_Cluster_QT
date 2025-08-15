# Development Guide

## Getting Started

### Development Environment Setup

#### Prerequisites
- **Qt Creator**: Latest version with Qt 6.4+ support
- **Git**: Version control
- **Code Editor**: Qt Creator recommended, VS Code as alternative
- **Terminal**: For build scripts and debugging

#### Project Structure Overview
```
PiRacer_Instrument_Cluster_QT/
├── src/                    # C++ backend source code
│   ├── main.cpp           # Application entry point
│   ├── canreceiver.*      # CAN bus communication
│   └── dbusreceiver.*     # DBus communication
├── content/               # QML UI components  
│   ├── Screen01.qml       # Main dashboard screen
│   ├── BatteryBar.ui.qml  # Battery indicator
│   ├── DashboardData*.qml # Data management components
│   └── WeatherData.qml    # Weather integration
├── imports/               # Custom QML modules
├── build-scripts/         # Build automation
└── test-scripts/          # Testing utilities
```

### Building the Project

#### Native Development Build
```bash
# Make build script executable
chmod +x build-native.sh

# Build for development/testing
./build-native.sh

# Run the application
./build-native/UntitledProjectApp
```

#### Cross-compilation for Raspberry Pi
```bash
# Set up cross-compilation environment (one-time setup)
# Install Raspberry Pi cross-compilation toolchain

# Make build script executable  
chmod +x build-raspi.sh

# Cross-compile for Raspberry Pi
./build-raspi.sh

# Deploy to target device
./deploy-static.sh
```

---

## Architecture Deep Dive

### Application Lifecycle
1. **Initialization** (`main.cpp`):
   - Qt application setup
   - CAN receiver initialization
   - DBus receiver initialization  
   - QML engine configuration
   - Context property registration

2. **Runtime Loop**:
   - CAN data reception (10Hz)
   - Signal processing (One Euro Filter)
   - UI updates (60 FPS)
   - Weather data refresh (on-demand)

3. **Shutdown**:
   - Resource cleanup
   - Socket closure
   - Graceful exit

### Threading Model
- **Main Thread**: UI rendering, QML execution
- **CAN Reader**: Asynchronous socket reading
- **Timers**: Qt timer-based periodic tasks
- **Network**: Qt network requests for weather data

### Memory Management
- **Qt Object System**: Parent-child ownership model
- **QML Engine**: Automatic garbage collection
- **C++ Objects**: RAII and smart pointers
- **Resource Cleanup**: Explicit cleanup in destructors

---

## Component Development

### Creating New QML Components

#### 1. Basic Component Structure
```qml
// content/NewComponent.qml
import QtQuick 6.4
import QtQuick.Controls 6.4

Item {
    id: root
    
    // Public properties
    property string title: "Default Title"
    property bool enabled: true
    
    // Private properties
    property real _internalValue: 0.0
    
    // Signals
    signal clicked()
    signal valueChanged(real value)
    
    // Component implementation
    Rectangle {
        anchors.fill: parent
        color: root.enabled ? "#77C000" : "#666666"
        
        Text {
            anchors.centerIn: parent
            text: root.title
            color: "white"
        }
        
        MouseArea {
            anchors.fill: parent
            onClicked: root.clicked()
        }
    }
}
```

#### 2. Register in qmldir
```
// content/qmldir
module content
# ... existing components ...
NewComponent 1.0 NewComponent.qml
```

#### 3. Use in Main Screen
```qml
// content/Screen01.qml
NewComponent {
    x: 100
    y: 100
    width: 200
    height: 50
    title: "Custom Button"
    onClicked: console.log("Button clicked!")
}
```

### Adding C++ Backend Components

#### 1. Create Header File
```cpp
// src/newsensor.h
#ifndef NEWSENSOR_H
#define NEWSENSOR_H

#include <QObject>
#include <QTimer>

class NewSensor : public QObject
{
    Q_OBJECT
    Q_PROPERTY(double value READ value NOTIFY valueChanged)

public:
    explicit NewSensor(QObject *parent = nullptr);
    
    double value() const { return m_value; }

signals:
    void valueChanged();

private slots:
    void updateValue();

private:
    QTimer *m_timer;
    double m_value;
};

#endif // NEWSENSOR_H
```

#### 2. Implement Source File
```cpp
// src/newsensor.cpp
#include "newsensor.h"
#include <QDebug>
#include <QRandomGenerator>

NewSensor::NewSensor(QObject *parent)
    : QObject(parent), m_value(0.0)
{
    m_timer = new QTimer(this);
    connect(m_timer, &QTimer::timeout, this, &NewSensor::updateValue);
    m_timer->start(1000); // Update every second
}

void NewSensor::updateValue()
{
    double newValue = QRandomGenerator::global()->bounded(100.0);
    if (m_value != newValue) {
        m_value = newValue;
        emit valueChanged();
        qDebug() << "Sensor value updated:" << m_value;
    }
}
```

#### 3. Register in Main Application
```cpp
// src/main.cpp
#include "newsensor.h"

int main(int argc, char *argv[])
{
    // ... existing setup ...
    
    // Create sensor instance
    NewSensor newSensor;
    
    // Register with QML context
    engine.rootContext()->setContextProperty("newSensor", &newSensor);
    
    // ... rest of main function ...
}
```

#### 4. Use in QML
```qml
// content/Screen01.qml
Text {
    text: "Sensor Value: " + newSensor.value.toFixed(2)
    color: "white"
}
```

---

## Testing and Debugging

### Unit Testing Setup

#### 1. Create Test Directory
```bash
mkdir tests
cd tests
```

#### 2. Qt Test Framework
```cpp
// tests/test_canreceiver.cpp
#include <QtTest>
#include "../src/canreceiver.h"

class TestCanReceiver : public QObject
{
    Q_OBJECT

private slots:
    void testConnection();
    void testDataReception();
    void testErrorHandling();
};

void TestCanReceiver::testConnection()
{
    CanReceiver receiver;
    receiver.connectToCan("vcan0"); // Virtual CAN for testing
    QVERIFY(receiver.connected());
}

void TestCanReceiver::testDataReception()
{
    CanReceiver receiver;
    QSignalSpy spy(&receiver, &CanReceiver::dataReceived);
    
    // Simulate CAN data...
    QVERIFY(spy.wait(1000));
    QCOMPARE(spy.count(), 1);
}

#include "test_canreceiver.moc"
QTEST_MAIN(TestCanReceiver)
```

#### 3. CMake Test Configuration
```cmake
# tests/CMakeLists.txt
find_package(Qt6 REQUIRED COMPONENTS Test)

add_executable(test_canreceiver test_canreceiver.cpp)
target_link_libraries(test_canreceiver Qt6::Test)

add_test(NAME CanReceiverTest COMMAND test_canreceiver)
```

### Debugging Techniques

#### 1. QML Debugging
```qml
// Enable debug output
Rectangle {
    Component.onCompleted: {
        console.log("Component loaded:", this)
        console.log("Properties:", JSON.stringify(this, null, 2))
    }
    
    onPropertyChanged: {
        console.log("Property changed:", property, "to:", value)
    }
}
```

#### 2. C++ Debugging
```cpp
// Use Qt's debug macros
#include <QDebug>
#include <QLoggingCategory>

Q_LOGGING_CATEGORY(canReceiver, "app.canreceiver")

void CanReceiver::processData(const QByteArray &data)
{
    qCDebug(canReceiver) << "Processing data:" << data.toHex();
    qCInfo(canReceiver) << "Speed:" << speed << "RPM:" << rpm;
}
```

#### 3. Performance Profiling
```bash
# Use Valgrind for memory analysis
valgrind --tool=memcheck --leak-check=full ./UntitledProjectApp

# Use perf for CPU profiling  
perf record -g ./UntitledProjectApp
perf report
```

### Testing Scripts

#### 1. CAN Data Simulation
```bash
#!/bin/bash
# test_can_data.sh - Simulate realistic CAN data

# Setup virtual CAN interface
sudo modprobe vcan
sudo ip link add dev vcan0 type vcan
sudo ip link set up vcan0

# Send test data
while true; do
    speed=$((RANDOM % 100 + 20))  # 20-120 cm/s
    rpm=$((speed * 20 + 1000))    # RPM based on speed
    
    # Format as CAN frame
    cansend vcan0 123#$(printf "%04x%02x%04x%02x" $speed 0 $rpm 0)
    
    sleep 0.1  # 10Hz update rate
done
```

#### 2. DBus Testing
```python
#!/usr/bin/env python3
# test_dbus_service.py

import dbus
import dbus.service
import json
import time
from dbus.mainloop.glib import DBusGMainLoop
from gi.repository import GLib

class TestDBusService(dbus.service.Object):
    def __init__(self):
        DBusGMainLoop(set_as_default=True)
        bus_name = dbus.service.BusName("org.team7.IC", bus=dbus.SessionBus())
        dbus.service.Object.__init__(self, bus_name, "/CarInformation")
        
        # Start data simulation
        GLib.timeout_add(1000, self.send_test_data)
    
    @dbus.service.signal("org.team7.IC.Interface")
    def DataReceived(self, data_json):
        pass
    
    def send_test_data(self):
        data = {
            "battery_capacity": 85.0 + (time.time() % 30) - 15,  # Simulate changing battery
            "charging_current": 1500.0 if time.time() % 10 < 5 else 0.0  # Simulate charging cycles
        }
        self.DataReceived(json.dumps(data))
        return True  # Continue timer

if __name__ == "__main__":
    service = TestDBusService()
    loop = GLib.MainLoop()
    loop.run()
```

---

## Signal Processing Development

### One Euro Filter Implementation

#### Understanding the Algorithm
The One Euro Filter adapts its smoothing based on signal velocity:

```qml
// Simplified implementation
function oneEuroFilter(value, timestamp) {
    var dt = (timestamp - previousTime) / 1000.0
    
    // Calculate derivative (velocity)
    var derivative = (value - previousValue) / dt
    
    // Smooth the derivative
    smoothedDerivative = lowPassFilter(derivative, smoothedDerivative, alphaDerivative)
    
    // Calculate adaptive cutoff
    var cutoff = minCutoff + beta * Math.abs(smoothedDerivative)
    
    // Apply main filter
    var alpha = calculateAlpha(cutoff, dt)
    return lowPassFilter(value, previousValue, alpha)
}
```

#### Tuning Parameters
- **minCutoff**: Higher = more smoothing, lower = more responsive
- **beta**: Higher = more adaptation to velocity, lower = more consistent smoothing  
- **derivateCutoff**: Controls smoothing of velocity calculation

#### Testing Filter Performance
```qml
// Add debug visualization
property var filterHistory: []

function recordFilterData(raw, filtered) {
    filterHistory.push({
        timestamp: Date.now(),
        raw: raw,
        filtered: filtered
    })
    
    // Keep only last 100 samples
    if (filterHistory.length > 100) {
        filterHistory.shift()
    }
}
```

### Custom Signal Processing

#### Moving Average Filter
```qml
property var speedBuffer: []
property int bufferSize: 10

function movingAverageFilter(newValue) {
    speedBuffer.push(newValue)
    if (speedBuffer.length > bufferSize) {
        speedBuffer.shift()
    }
    
    var sum = speedBuffer.reduce(function(a, b) { return a + b }, 0)
    return sum / speedBuffer.length
}
```

#### Kalman Filter (Simplified)
```qml
property real kalmanGain: 0.1
property real estimate: 0.0
property real errorCovariance: 1.0

function kalmanFilter(measurement, processNoise, measurementNoise) {
    // Prediction step
    var predictedError = errorCovariance + processNoise
    
    // Update step
    kalmanGain = predictedError / (predictedError + measurementNoise)
    estimate = estimate + kalmanGain * (measurement - estimate)
    errorCovariance = (1 - kalmanGain) * predictedError
    
    return estimate
}
```

---

## Performance Optimization

### QML Performance Best Practices

#### 1. Minimize Property Bindings
```qml
// Bad: Complex binding recalculated frequently
color: Qt.rgba(speed / 100, (100 - speed) / 100, 0, 1)

// Good: Update only when needed
property color speedColor: "#77C000"

onSpeedChanged: {
    speedColor = Qt.rgba(speed / 100, (100 - speed) / 100, 0, 1)
}
```

#### 2. Use Loaders for Dynamic Content
```qml
Loader {
    id: dynamicComponent
    active: showAdvancedView
    source: "AdvancedDashboard.qml"
}
```

#### 3. Optimize Animations
```qml
// Use hardware-accelerated properties
NumberAnimation { 
    property: "opacity"  // GPU accelerated
    easing.type: Easing.OutQuad  // Efficient easing
}

// Avoid animating:
// - width/height (unless necessary)
// - complex property bindings
// - text content frequently
```

### C++ Performance Optimization

#### 1. Minimize Signal Emissions
```cpp
void CanReceiver::updateSpeed(float newSpeed)
{
    // Only emit if value actually changed
    if (!qFuzzyCompare(m_speed, newSpeed)) {
        m_speed = newSpeed;
        emit speedChanged();
    }
}
```

#### 2. Use Efficient Data Structures
```cpp
// Use QVarLengthArray for small, known-size collections
QVarLengthArray<float, 10> speedBuffer;

// Use reserve() for QVector when size is known
QVector<DataPoint> history;
history.reserve(1000);
```

#### 3. Optimize String Operations
```cpp
// Build strings efficiently
QString message;
message.reserve(100);  // Pre-allocate
message += "Speed: ";
message += QString::number(speed, 'f', 1);
message += " cm/s";
```

---

## Contributing Guidelines

### Code Style

#### QML Style
```qml
// Use camelCase for properties and functions
property real currentSpeed: 0.0
function updateDisplayValue() { }

// Use descriptive component IDs
Rectangle {
    id: speedDisplayBackground
    
    Text {
        id: speedValueText
        // ...
    }
}

// Group related properties
Rectangle {
    // Geometry first
    x: 100
    y: 50
    width: 200
    height: 100
    
    // Appearance second
    color: "#000000"
    border.color: "#77C000"
    border.width: 2
    
    // Behavior last
    opacity: enabled ? 1.0 : 0.5
}
```

#### C++ Style
```cpp
// Use Qt naming conventions
class CanReceiver : public QObject  // PascalCase for classes
{
    Q_OBJECT
    
private:
    float m_speed;          // m_ prefix for members
    QTimer *m_timer;        // Pointer notation style
    
public slots:
    void updateData();      // camelCase for functions
    
signals:
    void speedChanged();    // camelCase for signals
};
```

### Git Workflow

#### 1. Branch Naming
```bash
# Feature branches
git checkout -b feature/add-gear-indicator
git checkout -b feature/improve-filtering

# Bug fix branches  
git checkout -b bugfix/can-connection-timeout
git checkout -b bugfix/weather-api-error

# Documentation
git checkout -b docs/update-api-documentation
```

#### 2. Commit Messages
```bash
# Good commit messages
git commit -m "feat: add One Euro filter for speed smoothing"
git commit -m "fix: prevent CAN receiver memory leak"
git commit -m "docs: update API documentation for DBus interface"
git commit -m "refactor: simplify weather data component"

# Use conventional commits format:
# type(scope): description
# 
# Types: feat, fix, docs, style, refactor, test, chore
```

#### 3. Pull Request Process
1. Create feature branch from main
2. Implement changes with tests
3. Update documentation if needed
4. Submit pull request with description
5. Address review feedback
6. Merge after approval

### Documentation Standards

#### 1. Code Documentation
```cpp
/**
 * @brief Processes incoming CAN frame data
 * @param frame Raw CAN frame structure
 * 
 * Extracts speed and RPM from the CAN frame according to the
 * defined protocol. Speed is in cm/s, RPM is engine revolutions
 * per minute.
 * 
 * @note Frame format: [speed_high, speed_low, speed_frac, 
 *                      rpm_high, rpm_low, rpm_frac, reserved, reserved]
 */
void CanReceiver::processCanFrame(const struct can_frame &frame);
```

#### 2. QML Documentation
```qml
/**
 * BatteryBar - Visual battery level indicator
 * 
 * Displays battery level as a horizontal bar with color coding:
 * - Green (>70%): Normal operation
 * - Yellow (40-70%): Medium level
 * - Orange (20-40%): Low battery warning
 * - Red (<20%): Critical battery level
 * 
 * @property {int} batteryLevel - Battery percentage (0-100)
 * @property {bool} useRealData - Use real vs demo data
 */
Rectangle {
    id: batteryBar
    // ...
}
```

This development guide provides the foundation for contributing to and extending the PiRacer Instrument Cluster project. Follow these patterns and practices to maintain code quality and project consistency.
