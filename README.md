# PiRacer Instrument Cluster QT

A sophisticated real-time automotive instrument cluster application built with Qt QML for the PiRacer platform. This project provides a full-featured dashboard display with CAN bus integration, DBus communication, real-time weather data, and advanced signal filtering.

## Features

### 🚗 Core Dashboard Functionality
- **Real-time Speed Display**: Shows vehicle speed in cm/s with smooth animations
- **RPM Monitoring**: Engine RPM display with color-coded indicators
- **CAN Bus Integration**: Reads real vehicle data from CAN bus interface
- **One Euro Filtering**: Advanced signal smoothing for stable speed/RPM readings
- **Turn Signal Indicators**: Interactive left/right turn signal controls

### 🔋 Battery & Power Management
- **Battery Level Display**: Visual battery bar with color-coded states (critical, low, medium, normal)
- **Charging Status**: Real-time charging current monitoring via DBus
- **Charging Indicator**: Visual charging icon when current exceeds threshold (>1000mA)

### 🌤️ Weather Integration
- **Real-time Weather**: Current temperature and weather conditions
- **Location Detection**: IP-based geolocation with GPS fallback
- **Weather Icons**: Dynamic weather icons based on current conditions
- **Multiple Locations**: Click to cycle through different locations

### 🎮 Input & Control
- **Gamepad Support**: ShanWan gamepad integration for PiRacer control
- **Interactive UI**: Click-to-cycle weather locations
- **Escape Key**: Exit application with ESC key

### 📡 Communication
- **CAN Bus Support**: Linux SocketCAN integration for real vehicle data
- **DBus Interface**: Communication with PiRacer services
- **Dual Mode Operation**: Switches between real CAN data and simulation mode

## Architecture

### Qt QML Application Structure
```
├── main.qml              # Application entry point
├── content/
│   ├── App.qml           # Main application window
│   ├── Screen01.qml      # Primary dashboard screen
│   ├── BatteryBar.ui.qml # Battery level indicator
│   ├── DashboardDataCAN.qml   # CAN bus data management
│   ├── DashboardDataDBus.qml  # DBus data management
│   ├── WeatherData.qml   # Weather data integration
│   └── VectorIcon.qml    # Interactive vector icons
├── src/
│   ├── main.cpp          # C++ application entry
│   ├── canreceiver.h/cpp # CAN bus communication
│   └── dbusreceiver.h/cpp# DBus communication
└── imports/              # Custom QML modules
```

### Data Flow
1. **CAN Bus**: `canreceiver.cpp` → `DashboardDataCAN.qml` → `Screen01.qml`
2. **DBus**: `dbusreceiver.cpp` → `DashboardDataDBus.qml` → `Screen01.qml`
3. **Weather**: `WeatherData.qml` → `Screen01.qml`
4. **Filtering**: Raw data → One Euro Filter → Smooth animations

## Technology Stack

### Frontend
- **Qt 6.4+**: Modern Qt framework
- **QML**: Declarative UI language
- **Qt Quick Controls**: UI components
- **Qt Positioning**: Location services

### Backend
- **C++**: Core application logic
- **Linux SocketCAN**: CAN bus communication
- **Qt DBus**: Inter-process communication
- **Python**: PiRacer gamepad control

### Hardware Integration
- **CAN Interface**: `can10` interface for vehicle data
- **ShanWan Gamepad**: Vehicle control input
- **PiRacer Platform**: Standard or Pro variants

## Signal Processing

### One Euro Filter
The application implements a sophisticated One Euro Filter for signal smoothing:

- **Adaptive Filtering**: Adjusts smoothing based on signal velocity
- **Configurable Parameters**:
  - `minCutoff`: 1.0 Hz (baseline smoothing)
  - `beta`: 0.1 (adaptation sensitivity)
  - `derivateCutoff`: 1.0 Hz (derivative smoothing)
- **Dual Channel**: Separate filtering for speed and RPM
- **Real-time Processing**: 10Hz sampling rate

### Data Validation
- **RPM Threshold**: Values below 50 RPM treated as zero
- **Connection Monitoring**: Real-time CAN/DBus connection status
- **Error Handling**: Graceful fallback to simulation mode

## User Interface

### Dashboard Layout
- **Central Speed Display**: Large, prominent speed reading
- **RPM Indicator**: Side-mounted RPM display with gear icon
- **Battery Bar**: Bottom-mounted battery level indicator
- **Weather Widget**: Top-right weather and time display
- **Status Indicators**: CAN connection and charging status

### Visual Design
- **Dark Theme**: Automotive-grade dark interface
- **Color Coding**:
  - Green (#77C000): Normal status, turn signals
  - Red (#F44336): Critical battery level
  - Orange (#FF9800): Low battery warning
  - Yellow (#FFEB3B): Medium battery level
- **Smooth Animations**: 300-400ms transitions
- **Responsive Layout**: Scales for different screen sizes

### Interactive Elements
- **Turn Signals**: Click left/right arrows for turn indicators
- **Weather Cycling**: Click weather widget to refresh/cycle locations
- **Battery Monitoring**: Real-time charging status display

## Configuration Files

### CAN Bus Setup
```cpp
// CAN interface configuration
const QString interface = "can10";
// Message ID for speed/RPM data
const uint32_t CAN_ID = 0x123;
```

### DBus Service
```cpp
// DBus service configuration
Service: "org.team7.IC"
Path: "/CarInformation"
Interface: "org.team7.IC.Interface"
```

### Weather API
```javascript
// Open-Meteo API configuration
Base URL: "http://api.open-meteo.com/v1/forecast"
Parameters: temperature_2m, weather_code, is_day
Location: IP-based geolocation with GPS fallback
```

## Data Formats

### CAN Message Format
```
ID: 0x123 (8 bytes)
[0-1]: Speed integer (big-endian)
[2]:   Speed fraction (0-99)
[3-4]: RPM integer (big-endian)  
[5]:   RPM fraction (0-99)
[6-7]: Reserved
```

### DBus Message Format
```json
{
  "battery_capacity": 85.5,
  "charging_current": 1250.0
}
```

## Development Features

### Debug Output
- **Timestamped Logging**: All operations include precise timestamps
- **Filter State Monitoring**: Real-time filter coefficient display
- **Connection Status**: Detailed CAN/DBus connection logging
- **Performance Metrics**: Signal processing timing information

### Testing Support
- **Simulation Mode**: Works without physical hardware
- **Test Scripts**: CAN data simulation (`test_can_data.sh`)
- **DBus Testing**: Battery/charging simulation scripts
- **Mock Data**: Realistic simulated vehicle parameters

### Error Handling
- **Graceful Degradation**: Falls back to simulation when hardware unavailable
- **Connection Recovery**: Automatic reconnection attempts
- **Input Validation**: Robust data parsing and validation
- **Resource Management**: Proper cleanup of system resources

## Performance Characteristics

### Real-time Requirements
- **Update Rate**: 10Hz CAN data sampling
- **Filter Latency**: <100ms signal delay
- **UI Refresh**: 60 FPS smooth animations
- **Memory Usage**: Optimized for embedded systems

### System Requirements
- **Qt Version**: 6.4 or higher
- **Platform**: Linux (Raspberry Pi optimized)
- **CAN Interface**: SocketCAN compatible
- **Python**: 3.x for gamepad support
- **Memory**: 512MB RAM minimum
- **Storage**: 100MB application size

## Future Enhancements

### Planned Features
- **GPS Navigation**: Route display and turn-by-turn directions
- **Multiple Screens**: Additional dashboard views
- **Data Logging**: Historical driving data storage
- **Customization**: User-configurable layouts and themes
- **Voice Integration**: Audio feedback and commands
- **Mobile App**: Companion smartphone application

### Hardware Expansion
- **Additional Sensors**: Temperature, pressure monitoring
- **Camera Integration**: Rear-view camera display
- **Audio System**: Music and radio integration
- **Wireless Connectivity**: WiFi and Bluetooth support

## License

This project is licensed under the Qt Commercial License or GPL-3.0. See individual file headers for specific licensing information.

## Credits

Developed for the PiRacer platform using Qt Design Studio and Qt Creator. Weather data provided by Open-Meteo API.
