# DES Project - Instrument Cluster

## Introduction
The Instrument Cluster is a project that displays real-time vehicle data on a digital dashboard, utilizing a Raspberry Pi for processing and visualization.

Speed data is transmitted to the Raspberry Pi directly via the CAN bus. Concurrently, battery-related data is received via I2C communication and then integrated with the graphical user interface (GUI) through the D-Bus messaging system. The entire GUI was developed as a Qt application to ensure a responsive and real-time display.

## Features

### 🚗 Core Dashboard Functionality
- **Real-time Speed Display**: Shows vehicle speed in cm/s with smooth animations
- **RPM Monitoring**: Engine RPM display
- **CAN Integration**: Reads real vehicle data from CAN interface
- **One Euro Filtering**: Advanced signal smoothing for stable speed/RPM readings
- **Turn Signal Indicators**: Interactive left/right turn signal controls

### 🔋 Battery & Power Management
- **Battery Level Display**: Visual battery bar with color-coded states (critical, low, medium, normal)
- **Charging Status**: Real-time charging current monitoring via DBus
- **Charging Indicator**: Visual charging icon when current exceeds threshold (>100mA)

### 🌤️ Weather Integration
- **Real-time Weather**: Current temperature and weather conditions
- **Location Detection**: IP-based geolocation with GPS fallback
- **Weather Icons**: Dynamic weather icons based on current conditions

### 🎮 Input & Control
- **Gamepad Support**: ShanWan gamepad integration for PiRacer control

### 📡 Communication
- **CAN Support**: Linux SocketCAN integration for real vehicle data
- **DBus Interface**: Communication with PiRacer services

## Architecture

### System Architecture

```mermaid
graph TD
    subgraph "Host PC"
        direction LR
        A["<i class='fas fa-laptop-code'></i> Qt Creator Project"] -- Cross-Compile --> B["<i class='fas fa-cogs'></i> Executable File"]
    end

    subgraph "Hardware"
        direction LR
        C["<i class='fas fa-gamepad'></i> Wireless Controller"] -- "2.4GHz RF" --> M["<i class='fab fa-usb'></i> USB Dongle"]
        D["<i class='fas fa-tachometer-alt'></i> Speed Sensor"] -- Interrupt Pulse --> E["<i class='fab fa-arduino'></i> Arduino"]
        E -- "<i class='fas fa-microchip'></i> SPI" --> K["MCP2515<br/>(CAN Controller)"]
        K -- "CAN Frame (Speed Data)" --> F(("<i class='fas fa-bus'></i> CAN Bus"))
        L["<i class='fas fa-battery-half'></i> INA219<br/>(Battery Monitor)"]
    end

    subgraph "Raspberry Pi (Target PC)"
        direction TB
        subgraph "Background Services"
            direction LR
            N["<i class='fab fa-python'></i> Input Service"] -- Controller Events --> I
            H["<i class='fab fa-python'></i> Power Service"] -- Power Status --> I(("<i class='fas fa-route'></i> D-Bus"))
        end
        
        G["<i class='fab fa-raspberry-pi'></i> <b>Qt Application</b> (GUI)"]
        J["<i class='fas fa-tv'></i> Dashboard Display"]

        B -.-> |"<i class='fas fa-file-upload'></i> scp"| G
        M -- "USB HID Events" --> N
        L -- "I2C Bus (Power Data)" --> H
        F -- "<i class='fas fa-network-wired'></i> SocketCAN API" --> G
        I -- "D-Bus Signal Subscription" --> G
        G -- Renders --> J
    end

    %% Styling
    classDef dev fill:#ede7f6,stroke:#5e35b1,stroke-width:2px,color:#212121;
    classDef hardware fill:#eceff1,stroke:#546e7a,stroke-width:2px,color:#212121;
    classDef service fill:#e0f7fa,stroke:#00838f,stroke-width:2px,color:#212121;
    classDef app fill:#fff8e1,stroke:#fbc02d,stroke-width:3px,color:#424242;

    class A,B dev;
    class C,D,E,F,K,L,M hardware;
    class H,I,N service;
    class G,J app;
```

### Full-Stack Software Architecture
```mermaid
graph TB
    %% Application Startup Layer
    subgraph "Application Startup"
        main_cpp[main.cpp]
        python_processes[Python Process Management]
    end
    
    %% QML UI Layer
    subgraph "QML User Interface"
        main_qml[main.qml]
        app_qml[App.qml]
        screen01[Screen01.qml]
    end
    
    %% Data Management Layer  
    subgraph "Data Management"
        can_data[DashboardDataCAN.qml]
        dbus_data[DashboardDataDBus.qml]
        weather_data[WeatherData.qml]
    end
    
    %% UI Components Layer
    subgraph "UI Components"
        vector_icon[VectorIcon.qml]
        battery_ui[BatteryBar.ui.qml]
        speed_ui[Speed Display]
    end
    
    %% C++ Backend Layer
    subgraph "C++ Backend Services"
        can_receiver[CanReceiver.cpp/h]
        dbus_receiver[DBusReceiver.cpp/h]
    end
    
    %% Python Services Layer
    subgraph "Python Services"
        dbus_sender[dbussender.py]
        rc_controller[rc_example.py]
    end
    
    %% Hardware/System Layer
    subgraph "Hardware & System"
        can_hardware[CAN Bus Hardware]
        piracer_hw[PiRacer Hardware]
        system_dbus[System DBus]
        gamepad[ShanWan Gamepad]
    end
    
    %% External Services
    subgraph "External Services"
        weather_api[Weather APIs]
    end
    
    %% Build & Deploy
    subgraph "Build System"
        cmake_build[CMakeLists.txt]
        deploy_scripts[build-native.sh<br/>build-raspi.sh]
    end
    
    %% Primary Application Flow
    main_cpp --> python_processes
    main_cpp --> main_qml
    main_qml --> app_qml
    app_qml --> screen01
    
    %% Data Flow Connections
    screen01 --> can_data
    screen01 --> dbus_data
    screen01 --> weather_data
    screen01 --> vector_icon
    screen01 --> battery_ui
    screen01 --> speed_ui
    
    %% Backend Integration
    can_data --> can_receiver
    dbus_data --> dbus_receiver
    
    %% C++ Context Registration
    main_cpp -.-> can_receiver
    main_cpp -.-> dbus_receiver
    
    %% Python Service Connections
    python_processes --> dbus_sender
    python_processes --> rc_controller
    
    %% Hardware Interface
    can_receiver <--> can_hardware
    dbus_receiver <--> system_dbus
    dbus_sender <--> system_dbus
    dbus_sender <--> piracer_hw
    rc_controller <--> gamepad
    rc_controller <--> piracer_hw
    rc_controller --> system_dbus
    
    %% External API
    weather_data <--> weather_api
    
    %% Build Dependencies
    cmake_build --> deploy_scripts
    deploy_scripts --> main_cpp
    
    %% UI Component Dependencies
    vector_icon --> dbus_data
    battery_ui --> dbus_data
    speed_ui --> can_data
    
    %% Styling
    classDef startupLayer fill:#ffebee,stroke:#c62828,stroke-width:2px
    classDef uiLayer fill:#e8f5e8,stroke:#2e7d32,stroke-width:2px
    classDef dataLayer fill:#e3f2fd,stroke:#1565c0,stroke-width:2px
    classDef componentLayer fill:#f3e5f5,stroke:#7b1fa2,stroke-width:2px
    classDef backendLayer fill:#fff3e0,stroke:#ef6c00,stroke-width:2px
    classDef pythonLayer fill:#e0f2f1,stroke:#00695c,stroke-width:2px
    classDef hardwareLayer fill:#fce4ec,stroke:#ad1457,stroke-width:2px
    classDef externalLayer fill:#f1f8e9,stroke:#558b2f,stroke-width:2px
    classDef buildLayer fill:#e8eaf6,stroke:#3f51b5,stroke-width:2px
    
    class main_cpp,python_processes startupLayer
    class main_qml,app_qml,screen01 uiLayer
    class can_data,dbus_data,weather_data dataLayer
    class vector_icon,battery_ui,speed_ui componentLayer
    class can_receiver,dbus_receiver backendLayer
    class dbus_sender,rc_controller pythonLayer
    class can_hardware,piracer_hw,system_dbus,gamepad hardwareLayer
    class weather_api externalLayer
    class cmake_build,deploy_scripts buildLayer
```

### Data Flow
1. **CAN**: `can_new.ino` → `canreceiver.cpp` → `DashboardDataCAN.qml` → `Screen01.qml`
2. **DBus**: `dbussender.py` → `dbusreceiver.cpp` → `DashboardDataDBus.qml` → `Screen01.qml`
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
- **Linux SocketCAN**: CAN communication
- **DBus**: Inter-process communication (DBus)
- **Python**: PiRacer gamepad control

### Hardware Integration
- **CAN Interface**: `can10` interface for vehicle data
- **ShanWan Gamepad**: Vehicle control input

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
- **RPM Indicator**: Side-mounted RPM display
- **Battery Bar**: Bottom-mounted battery level indicator
- **Weather Widget**: Top-right weather and time display
- **Status Indicators**: CAN connection and charging status

### Visual Design
- **Dark Theme**
- **Color Coding**:
  - Green (#00FF00): Normal status, turn signals
  - Red (#F44336): Critical battery level
  - Orange (#FF9800): Low battery warning
  - Yellow (#FFEB3B): Medium battery level
- **Smooth Animations**: 300-400ms transitions
- **Responsive Layout**: Scales for different screen sizes

### Interactive Elements
- **Turn Signals**: Pressing the L1 and R1 buttons on the controller activates the left and right turn signals, respectively. The signal is deactivated by either pressing the same button again or by steering in the opposite direction.
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
    "charging_current": 1250.0,
    "left_turn_signal": false,
    "right_turn_signal": true
}
```


## License

This project is licensed under the Qt Commercial License or GPL-3.0. See individual file headers for specific licensing information.

## Credits

Developed for the PiRacer platform using Qt Design Studio and Qt Creator. Weather data provided by Open-Meteo API.
