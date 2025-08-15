# Configuration Guide

## System Requirements

### Software Dependencies
- **Qt Framework**: 6.4 or higher
- **Operating System**: Linux (Raspberry Pi OS recommended)
- **Python**: 3.7+ for gamepad support
- **CAN Utils**: Linux SocketCAN utilities
- **DBus**: System DBus service

### Hardware Requirements
- **Raspberry Pi**: 3B+ or higher (4B recommended for best performance)
- **CAN Interface**: MCP2515 CAN module or similar
- **Display**: HDMI/DSI display (800x480 minimum resolution)
- **Gamepad**: ShanWan compatible controller
- **SD Card**: 16GB minimum (Class 10 recommended)

---

## CAN Bus Configuration

### Hardware Setup
1. **Connect MCP2515 CAN Module**:
   ```
   MCP2515    Raspberry Pi
   VCC     →  3.3V (Pin 1)
   GND     →  GND (Pin 6)
   SCK     →  GPIO 11 (Pin 23)
   SI      →  GPIO 10 (Pin 19)
   SO      →  GPIO 9 (Pin 21)
   CS      →  GPIO 8 (Pin 24)
   INT     →  GPIO 25 (Pin 22)
   ```

2. **Enable SPI Interface**:
   ```bash
   sudo raspi-config
   # Navigate to: Interfacing Options → SPI → Enable
   ```

### Software Configuration

1. **Enable CAN Overlay** (`/boot/config.txt`):
   ```ini
   dtparam=spi=on
   dtoverlay=mcp2515-can0,oscillator=8000000,interrupt=25
   dtoverlay=spi-bcm2835-overlay
   ```

2. **Configure CAN Interface**:
   ```bash
   # Add to /etc/rc.local (before exit 0)
   sudo ip link set can0 up type can bitrate 500000
   sudo ip link set can0 txqueuelen 1000
   
   # Create can10 alias for compatibility
   sudo ip link add link can0 name can10 type can
   sudo ip link set can10 up
   ```

3. **Install CAN Utilities**:
   ```bash
   sudo apt update
   sudo apt install can-utils
   ```

4. **Test CAN Interface**:
   ```bash
   # Check interface status
   ip link show can0
   ip link show can10
   
   # Monitor CAN traffic
   candump can10
   
   # Send test message
   cansend can10 123#1122334455667788
   ```

---

## DBus Service Configuration

### Service Setup
1. **DBus Service File** (`/etc/dbus-1/system.d/org.team7.IC.conf`):
   ```xml
   <!DOCTYPE busconfig PUBLIC
    "-//freedesktop//DTD D-BUS Bus Configuration 1.0//EN"
    "http://www.freedesktop.org/standards/dbus/1.0/busconfig.dtd">
   <busconfig>
     <policy user="pi">
       <allow own="org.team7.IC"/>
       <allow send_destination="org.team7.IC"/>
       <allow receive_sender="org.team7.IC"/>
     </policy>
     <policy context="default">
       <allow send_destination="org.team7.IC"/>
       <allow receive_sender="org.team7.IC"/>
     </policy>
   </busconfig>
   ```

2. **Service Implementation** (Python example):
   ```python
   import dbus
   import dbus.service
   import json
   from gi.repository import GLib
   from dbus.mainloop.glib import DBusGMainLoop
   
   class CarInformationService(dbus.service.Object):
       def __init__(self):
           bus_name = dbus.service.BusName("org.team7.IC", 
                                          bus=dbus.SessionBus())
           dbus.service.Object.__init__(self, bus_name, "/CarInformation")
           self.battery_level = 85.0
           self.charging_current = 0.0
       
       @dbus.service.signal("org.team7.IC.Interface")
       def DataReceived(self, data_json):
           pass
       
       def emit_data(self):
           data = {
               "battery_capacity": self.battery_level,
               "charging_current": self.charging_current
           }
           self.DataReceived(json.dumps(data))
   ```

3. **Auto-start Service**:
   ```bash
   # Add to crontab for auto-start
   crontab -e
   # Add line:
   @reboot python3 /path/to/dbus_service.py
   ```

---

## Application Configuration

### Qt Environment Setup
1. **Install Qt 6.4+**:
   ```bash
   # On Raspberry Pi OS
   sudo apt update
   sudo apt install qt6-base-dev qt6-declarative-dev
   sudo apt install qt6-tools-dev qt6-tools-dev-tools
   ```

2. **Environment Variables** (add to `~/.bashrc`):
   ```bash
   export QT_QPA_PLATFORM=xcb
   export QT_QPA_FONTDIR=/usr/share/fonts
   export QML_IMPORT_PATH=/usr/lib/qt6/qml
   ```

### Display Configuration
1. **Framebuffer Setup** (`/boot/config.txt`):
   ```ini
   # Force HDMI output
   hdmi_force_hotplug=1
   
   # Set resolution
   hdmi_group=2
   hdmi_mode=87
   hdmi_cvt=800 480 60 6 0 0 0
   
   # Disable overscan
   disable_overscan=1
   ```

2. **Fullscreen Mode**:
   ```cpp
   // In main.cpp, the application automatically sets:
   flags: Qt.FramelessWindowHint
   visibility: Window.FullScreen
   ```

### Performance Optimization
1. **GPU Memory Split** (`/boot/config.txt`):
   ```ini
   gpu_mem=128
   ```

2. **System Tweaks**:
   ```bash
   # Disable swap for better real-time performance
   sudo dphys-swapfile swapoff
   sudo systemctl disable dphys-swapfile
   
   # Set CPU governor to performance
   echo 'performance' | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor
   ```

---

## Network Configuration

### Weather API Setup
1. **Internet Connection**: Ensure stable internet for weather data
2. **Firewall Configuration**:
   ```bash
   # Allow outbound HTTP for weather API
   sudo ufw allow out 80
   sudo ufw allow out 443
   ```

3. **DNS Configuration** (`/etc/systemd/resolved.conf`):
   ```ini
   [Resolve]
   DNS=8.8.8.8 8.8.4.4
   Domains=~.
   ```

### IP Geolocation
- **Service**: ip-api.com (free, no API key required)
- **Fallback**: Manual coordinates in WeatherData.qml
- **Rate Limits**: 1000 requests/day (sufficient for typical usage)

---

## Security Configuration

### System Hardening
1. **User Permissions**:
   ```bash
   # Add user to required groups
   sudo usermod -a -G dialout,spi,gpio,video pi
   ```

2. **File Permissions**:
   ```bash
   # Set executable permissions
   chmod +x build-native.sh
   chmod +x build-raspi.sh
   chmod +x test_*.sh
   ```

### CAN Bus Security
1. **Interface Access Control**:
   ```bash
   # Restrict CAN access to specific users
   sudo groupadd canbus
   sudo usermod -a -G canbus pi
   ```

2. **Message Filtering** (in application):
   ```cpp
   // Only accept messages from known IDs
   const std::set<uint32_t> ALLOWED_IDS = {0x123, 0x124, 0x125};
   ```

---

## Troubleshooting

### Common Issues

#### CAN Bus Not Working
```bash
# Check kernel modules
lsmod | grep can
# Should show: can, can_raw, mcp251x

# Check interface status
ip link show can0
# Should show: state UP

# Check for errors
dmesg | grep -i can
```

#### DBus Connection Failed
```bash
# Check DBus service status
dbus-send --session --print-reply --dest=org.freedesktop.DBus \
  /org/freedesktop/DBus org.freedesktop.DBus.ListNames

# Test manual connection
python3 -c "
import dbus
bus = dbus.SessionBus()
proxy = bus.get_object('org.team7.IC', '/CarInformation')
print('DBus connection successful')
"
```

#### Qt Application Crashes
```bash
# Run with debug output
export QT_LOGGING_RULES="*=true"
./UntitledProjectApp

# Check dependencies
ldd UntitledProjectApp
```

#### Weather Data Not Loading
```bash
# Test internet connectivity
ping -c 3 api.open-meteo.com

# Test API directly
curl "http://api.open-meteo.com/v1/forecast?latitude=40.7128&longitude=-74.0060&current=temperature_2m"
```

### Performance Issues

#### High CPU Usage
1. **Reduce Update Frequency**:
   ```qml
   // In Screen01.qml, increase timer interval
   Timer {
       interval: 200  // Reduce from 100ms to 200ms
   }
   ```

2. **Disable Debug Logging**:
   ```qml
   // Comment out console.log() statements in production
   ```

#### Memory Leaks
1. **Monitor Memory Usage**:
   ```bash
   top -p $(pgrep UntitledProjectApp)
   ```

2. **Qt Object Cleanup**:
   ```cpp
   // Ensure proper parent-child relationships
   object->setParent(this);
   ```

---

## Production Deployment

### Auto-start Configuration
1. **Systemd Service** (`/etc/systemd/system/instrument-cluster.service`):
   ```ini
   [Unit]
   Description=PiRacer Instrument Cluster
   After=graphical-session.target
   
   [Service]
   Type=simple
   User=pi
   Environment=DISPLAY=:0
   WorkingDirectory=/home/pi/PiRacer_Instrument_Cluster_QT
   ExecStart=/home/pi/PiRacer_Instrument_Cluster_QT/build-native/UntitledProjectApp
   Restart=always
   RestartSec=5
   
   [Install]
   WantedBy=graphical-session.target
   ```

2. **Enable Service**:
   ```bash
   sudo systemctl enable instrument-cluster.service
   sudo systemctl start instrument-cluster.service
   ```

### Update Mechanism
1. **Git-based Updates**:
   ```bash
   #!/bin/bash
   # update.sh
   cd /home/pi/PiRacer_Instrument_Cluster_QT
   git pull origin main
   ./build-native.sh
   sudo systemctl restart instrument-cluster.service
   ```

2. **Backup Configuration**:
   ```bash
   # Backup settings before update
   cp qtquickcontrols2.conf qtquickcontrols2.conf.bak
   tar -czf config-backup-$(date +%Y%m%d).tar.gz *.conf *.json
   ```
