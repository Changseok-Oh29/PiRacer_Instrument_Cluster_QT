# API Documentation

## C++ Classes

### CanReceiver Class

**File**: `src/canreceiver.h` / `src/canreceiver.cpp`

**Purpose**: Handles Linux SocketCAN communication for real-time vehicle data reception.

#### Properties

- `float speed` - Current vehicle speed in cm/s (read-only)
- `float rpm` - Current engine RPM (read-only)
- `bool connected` - CAN bus connection status (read-only)

#### Public Methods

```cpp
void connectToCan(const QString &interface = "can10")
void disconnectFromCan()
void startListening()
void stopListening()
```

#### Signals

```cpp
void speedChanged()           // Emitted when speed value updates
void rpmChanged()            // Emitted when RPM value updates
void connectedChanged()      // Emitted when connection status changes
void dataReceived(float speed, float rpm)  // Raw data reception
void errorOccurred(const QString &error)   // Error notifications
```

#### CAN Message Format

- **Message ID**: 0x123
- **Data Length**: 8 bytes
- **Format**: [speed_high, speed_low, speed_frac, rpm_high, rpm_low, rpm_frac, reserved, reserved]

---

### DBusReceiver Class

**File**: `src/dbusreceiver.h` / `src/dbusreceiver.cpp`

**Purpose**: Communicates with PiRacer system services via DBus for battery and charging data. Includes automatic retry logic for robust connection handling.

#### Properties

- `double battery` - Battery level percentage (0-100)
- `double chargingCurrent` - Charging current in milliamps
- `bool leftTurnSignal` - Left turn signal state
- `bool rightTurnSignal` - Right turn signal state

#### DBus Configuration

- **Service**: org.team7.IC
- **Path**: /CarInformation
- **Interface**: org.team7.IC.Interface
- **Signal**: DataReceived(QString dataJson)
- **Retry Logic**: 10 attempts with 2-second delays
- **Auto-reconnect**: Attempts connection after service startup

#### JSON Data Format

```json
{
  "battery_capacity": 85.5,
  "charging_current": 1250.0,
  "left_turn_signal": false,
  "right_turn_signal": true
}
```

#### Signals

```cpp
void batteryChanged()           // Battery level updated
void chargingCurrentChanged()   // Charging current updated
void leftTurnSignalChanged()    // Left turn signal state changed
void rightTurnSignalChanged()   // Right turn signal state changed
```

---

## QML Components

### DashboardDataCAN

**File**: `content/DashboardDataCAN.qml`

**Purpose**: QML wrapper for CAN bus data with connection management.

#### Properties

```qml
property real currentSpeed: 0.0        // Current vehicle speed
property real currentRpm: 0.0          // Current engine RPM
property bool canConnected: false      // Connection status
property string connectionStatus: ""    // Human-readable status
```

#### Methods

```qml
function reconnectCan()     // Reconnect to CAN interface
function disconnectCan()   // Disconnect from CAN interface
function updateValues()    // Refresh property values
```

---

### DashboardDataDBus

**File**: `content/DashboardDataDBus.qml`

**Purpose**: QML wrapper for DBus battery and charging data.

#### Properties

```qml
property real batteryLevel: 0.0        // Battery percentage
property real chargingCurrent: 0.0     // Charging current (mA)
property bool dbusConnected: false     // DBus connection status
property bool leftTurnSignal: false    // Left turn signal state
property bool rightTurnSignal: false   // Right turn signal state
```

---

### WeatherData

**File**: `content/WeatherData.qml`

**Purpose**: Real-time weather data integration with geolocation.

#### Properties

```qml
property string currentLocation: ""     // Current city/location
property real currentTemperature: 0.0  // Temperature in Celsius
property int weatherCode: 0            // Weather condition code
property bool isDay: true              // Day/night status
property string weatherDescription: "" // Human-readable weather
property string weatherIconUrl: ""     // Weather icon URL
property string currentTime: ""        // Formatted current time
property real latitude: 0.0           // GPS latitude
property real longitude: 0.0          // GPS longitude
```

#### Methods

```qml
function enableGeolocation()            // Enable GPS positioning
function disableGeolocation()           // Disable GPS positioning
function useIPGeolocation()             // Use IP-based location
function refreshWeather()               // Refresh weather data
function refreshLocation()              // Fetch IP data again to refresh weather data
function setLocation(lat, lon)          // Set manual coordinates
```

#### Weather API Integration

- **Provider**: Open-Meteo API
- **Endpoint**: http://api.open-meteo.com/v1/forecast
- **Update Frequency**: On location change or manual refresh
- **Fallback**: IP geolocation when GPS unavailable

---

### BatteryBar

**File**: `content/BatteryBar.ui.qml`

**Purpose**: Visual battery level indicator with color-coded states.

#### Properties

```qml
property int batteryLevel: 100         // Battery level (0-100)
property color batteryColor: "#77C000" // Current battery color
property bool useRealData: true       // Use real vs demo data
```

#### Color States

- **Critical (< 20%)**: #F44336 (Red)
- **Low (20-40%)**: #FF9800 (Orange)
- **Medium (40-70%)**: #FFEB3B (Yellow)
- **Normal (> 70%)**: #77C000 (Green)

---

## Python Services

### DBusService (dbussender.py)

**Purpose**: Provides DBus service for battery monitoring and turn signal communication.

#### Key Classes

- `CarInformationService`: Main DBus service class
- `TurnSignalClient`: Client for sending turn signal data

#### DBus Methods

```python
@dbus.service.method("org.team7.IC.Interface")
def setBattery(self, battery_level)      # Set battery level
def setCurrent(self, current_ma)         # Set charging current
def setTurnSignals(self, left, right)    # Set turn signal states
def getBattery(self)                     # Get current battery level
def getTurnSignals(self)                 # Get turn signal states
```

#### DBus Signals

```python
@dbus.service.signal("org.team7.IC.Interface")
def DataReceived(self, data_json)        # Emitted when data updates
```

### RC Controller (rc_example.py)

**Purpose**: Handles gamepad input for PiRacer control.

#### Features

- ShanWan gamepad support
- Throttle and steering control
- Real-time input processing

---

## Signal Processing

### One Euro Filter Implementation

**Location**: `content/Screen01.qml`

**Purpose**: Advanced signal smoothing for stable speed/RPM display.

#### Configuration Parameters

```qml
property real minCutoff: 1.0           // Minimum cutoff frequency (Hz)
property real beta: 0.1                // Cutoff slope adaptation
property real derivateCutoff: 1.0      // Derivative smoothing cutoff
```

#### Core Functions

```qml
function lowPassFilter(current, previous, alpha)
function calculateAlpha(cutoff, dt)
function oneEuroFilterSpeed(value, timestamp)
function oneEuroFilterRpm(value, timestamp)
```

#### Algorithm Details

1. **Derivative Calculation**: Rate of signal change
2. **Adaptive Cutoff**: Frequency adjustment based on signal velocity
3. **Low-pass Filtering**: Smooth signal transitions
4. **Temporal Processing**: 10Hz sampling with timestamp tracking

---

## Data Flow Architecture

### CAN Bus Data Flow

```
Physical CAN Bus → SocketCAN → CanReceiver C++ → DashboardDataCAN QML → Screen01 QML → One Euro Filter → UI Display
```

### DBus Data Flow

```
PiRacer Service → DBus → DBusReceiver C++ → DashboardDataDBus QML → Screen01 QML → UI Display
```

### Weather Data Flow

```
IP/GPS Location → Open-Meteo API → WeatherData QML → Screen01 QML → UI Display
```

---

## Error Handling

### CAN Bus Errors

- **Connection Timeout**: Automatic fallback to simulation mode
- **Invalid Data**: Data validation and filtering
- **Interface Errors**: Error signals with descriptive messages

### DBus Errors

- **Service Unavailable**: Graceful degradation with default values
- **JSON Parse Errors**: Robust error handling and logging
- **Connection Loss**: Automatic reconnection attempts

### Weather API Errors

- **Network Failures**: Fallback to cached data
- **API Limits**: Retry logic with exponential backoff
- **Location Errors**: Default to known coordinates

---

## Performance Considerations

### Real-time Requirements

- **CAN Sampling**: 10Hz (100ms intervals)
- **UI Updates**: 60 FPS smooth animations
- **Filter Latency**: <100ms signal delay
- **Memory Usage**: Optimized for embedded systems

### Threading Model

- **Main Thread**: UI rendering and QML execution
- **CAN Thread**: Asynchronous socket reading
- **Timer-based**: Weather updates and data sampling

### Resource Management

- **Socket Cleanup**: Proper CAN socket closure
- **Memory Leaks**: Qt parent-child ownership model
- **CPU Usage**: Efficient filter algorithms
