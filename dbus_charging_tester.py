#!/usr/bin/env python3
import dbus
import dbus.service
import dbus.mainloop.glib
from gi.repository import GLib
import datetime
import threading
import json
import time

class CarInformationTestService(dbus.service.Object):
    def __init__(self):
        bus_name = dbus.service.BusName("org.team7.IC", bus=dbus.SessionBus())
        dbus.service.Object.__init__(self, bus_name, "/CarInformation")
        self.battery_level = 0.0
        self.charging_current = 0.0
        print(f"[TEST_SERVICE] {datetime.datetime.now().strftime('%H:%M:%S.%f')[:-3]} ✅ DBus test service org.team7.IC started")

    @dbus.service.method("org.team7.IC.Interface", in_signature='d', out_signature='')
    def setBattery(self, battery_level):
        self.battery_level = float(battery_level)
        print(f"[TEST_SERVICE] {datetime.datetime.now().strftime('%H:%M:%S.%f')[:-3]} 🔋 Battery level set: {self.battery_level:.1f}%")
        self._emit_data_signal()

    @dbus.service.method("org.team7.IC.Interface", in_signature='d', out_signature='')
    def setChargingCurrent(self, current_ma):
        self.charging_current = float(current_ma)
        print(f"[TEST_SERVICE] {datetime.datetime.now().strftime('%H:%M:%S.%f')[:-3]} ⚡ Charging current set: {self.charging_current:.1f}mA")
        self._emit_data_signal()

    @dbus.service.method("org.team7.IC.Interface", in_signature='', out_signature='d')
    def getBattery(self):
        print(f"[TEST_SERVICE] {datetime.datetime.now().strftime('%H:%M:%S.%f')[:-3]} 📊 Battery level requested: {self.battery_level:.1f}%")
        return self.battery_level

    @dbus.service.method("org.team7.IC.Interface", in_signature='', out_signature='d')
    def getChargingCurrent(self):
        print(f"[TEST_SERVICE] {datetime.datetime.now().strftime('%H:%M:%S.%f')[:-3]} 📊 Charging current requested: {self.charging_current:.1f}mA")
        return self.charging_current
    
    def _emit_data_signal(self):
        """Emit signal with both battery and charging data"""
        data = {
            "battery_capacity": self.battery_level,
            "charging_current": self.charging_current
        }
        json_data = json.dumps(data)
        print(f"[TEST_SERVICE] {datetime.datetime.now().strftime('%H:%M:%S.%f')[:-3]} 📤 Emitting DataReceived signal: {json_data}")
        self.DataReceived(json_data)
    
    @dbus.service.signal("org.team7.IC.Interface", signature='s')
    def DataReceived(self, data_json):
        """Signal emitted when data is updated"""
        pass

def test_scenario_thread(service):
    """Thread function to run charging current test scenarios"""
    time.sleep(3)  # Wait for service to initialize
    
    print(f"\n[TESTER] {datetime.datetime.now().strftime('%H:%M:%S.%f')[:-3]} 🧪 Starting charging current test scenarios...")
    print(f"[TESTER] {datetime.datetime.now().strftime('%H:%M:%S.%f')[:-3]} 📋 Test Plan:")
    print(f"[TESTER] {datetime.datetime.now().strftime('%H:%M:%S.%f')[:-3]}    1. Low current (500mA) - Icon should be INVISIBLE")
    print(f"[TESTER] {datetime.datetime.now().strftime('%H:%M:%S.%f')[:-3]}    2. High current (1500mA) - Icon should be VISIBLE/GREEN")
    print(f"[TESTER] {datetime.datetime.now().strftime('%H:%M:%S.%f')[:-3]}    3. Cycle between low/high every 5 seconds")
    print(f"[TESTER] {datetime.datetime.now().strftime('%H:%M:%S.%f')[:-3]}    4. Battery level will increase gradually")
    
    # Test scenarios
    scenarios = [
        {"current": 500, "description": "Low current - Icon INVISIBLE", "duration": 5},
        {"current": 1500, "description": "High current - Icon VISIBLE", "duration": 5},
        {"current": 800, "description": "Medium current - Icon INVISIBLE", "duration": 3},
        {"current": 2000, "description": "Very high current - Icon VISIBLE", "duration": 3},
        {"current": 200, "description": "Very low current - Icon INVISIBLE", "duration": 3},
        {"current": 1200, "description": "Above threshold - Icon VISIBLE", "duration": 5},
    ]
    
    battery_level = 25.0  # Start at 25%
    scenario_index = 0
    
    while True:
        scenario = scenarios[scenario_index % len(scenarios)]
        
        print(f"\n[TESTER] {datetime.datetime.now().strftime('%H:%M:%S.%f')[:-3]} 🔄 Test Scenario {scenario_index + 1}")
        print(f"[TESTER] {datetime.datetime.now().strftime('%H:%M:%S.%f')[:-3]} 📝 {scenario['description']}")
        print(f"[TESTER] {datetime.datetime.now().strftime('%H:%M:%S.%f')[:-3]} ⚡ Setting current to {scenario['current']}mA")
        print(f"[TESTER] {datetime.datetime.now().strftime('%H:%M:%S.%f')[:-3]} 🔋 Setting battery to {battery_level:.1f}%")
        
        # Set the test values
        service.setChargingCurrent(scenario['current'])
        service.setBattery(battery_level)
        
        # Status indicators
        charging_status = "🟢 VISIBLE" if scenario['current'] > 1000 else "🔴 INVISIBLE"
        print(f"[TESTER] {datetime.datetime.now().strftime('%H:%M:%S.%f')[:-3]} 💡 Expected icon state: {charging_status}")
        
        # Wait for the scenario duration
        for i in range(scenario['duration']):
            time.sleep(1)
            print(f"[TESTER] {datetime.datetime.now().strftime('%H:%M:%S.%f')[:-3]} ⏰ Scenario time remaining: {scenario['duration'] - i - 1}s")
        
        # Increment battery level and scenario
        battery_level = min(100.0, battery_level + 5.0)  # Increase by 5% each cycle, max 100%
        if battery_level >= 100.0:
            battery_level = 25.0  # Reset to 25% when full
            
        scenario_index += 1

def interactive_mode(service):
    """Interactive mode for manual testing"""
    print(f"\n[INTERACTIVE] {datetime.datetime.now().strftime('%H:%M:%S.%f')[:-3]} 🎮 Interactive mode started")
    print(f"[INTERACTIVE] Commands available:")
    print(f"[INTERACTIVE]   battery <value>   - Set battery level (0-100)")
    print(f"[INTERACTIVE]   current <value>   - Set charging current in mA")
    print(f"[INTERACTIVE]   status           - Show current values")
    print(f"[INTERACTIVE]   test             - Run quick test sequence")
    print(f"[INTERACTIVE]   quit             - Exit interactive mode")
    
    while True:
        try:
            cmd = input(f"\n[INTERACTIVE] Enter command: ").strip().lower()
            
            if cmd == "quit":
                break
            elif cmd == "status":
                print(f"[INTERACTIVE] Current battery: {service.battery_level:.1f}%")
                print(f"[INTERACTIVE] Current charging: {service.charging_current:.1f}mA")
                print(f"[INTERACTIVE] Icon should be: {'VISIBLE' if service.charging_current > 1000 else 'INVISIBLE'}")
            elif cmd == "test":
                print(f"[INTERACTIVE] Running quick test...")
                service.setChargingCurrent(500)   # Invisible
                service.setBattery(50)
                time.sleep(2)
                service.setChargingCurrent(1500)  # Visible
                time.sleep(2)
                service.setChargingCurrent(800)   # Invisible
                time.sleep(2)
                print(f"[INTERACTIVE] Quick test completed")
            elif cmd.startswith("battery "):
                try:
                    value = float(cmd.split()[1])
                    if 0 <= value <= 100:
                        service.setBattery(value)
                    else:
                        print(f"[INTERACTIVE] Battery value must be 0-100")
                except:
                    print(f"[INTERACTIVE] Invalid battery value")
            elif cmd.startswith("current "):
                try:
                    value = float(cmd.split()[1])
                    service.setChargingCurrent(value)
                    print(f"[INTERACTIVE] Icon should be: {'VISIBLE' if value > 1000 else 'INVISIBLE'}")
                except:
                    print(f"[INTERACTIVE] Invalid current value")
            else:
                print(f"[INTERACTIVE] Unknown command: {cmd}")
                
        except KeyboardInterrupt:
            break
        except EOFError:
            break

if __name__ == "__main__":
    print(f"[MAIN] {datetime.datetime.now().strftime('%H:%M:%S.%f')[:-3]} 🚀 Starting D-Bus Charging Icon Tester")
    print(f"[MAIN] {datetime.datetime.now().strftime('%H:%M:%S.%f')[:-3]} 🎯 Purpose: Test charging icon visibility based on current")
    print(f"[MAIN] {datetime.datetime.now().strftime('%H:%M:%S.%f')[:-3]} 📏 Threshold: Icon visible when current > 1000mA")
    
    # Set up DBus main loop
    dbus.mainloop.glib.DBusGMainLoop(set_as_default=True)
    
    # Start DBus service
    try:
        service = CarInformationTestService()
        print(f"[MAIN] {datetime.datetime.now().strftime('%H:%M:%S.%f')[:-3]} ✅ DBus test service started")
    except Exception as e:
        print(f"[MAIN] {datetime.datetime.now().strftime('%H:%M:%S.%f')[:-3]} ❌ Failed to start DBus service: {e}")
        exit(1)
    
    # Ask user for test mode
    print(f"\n[MAIN] {datetime.datetime.now().strftime('%H:%M:%S.%f')[:-3]} 🤔 Choose test mode:")
    print(f"[MAIN]   1. Automatic test scenarios (cycles through different current values)")
    print(f"[MAIN]   2. Interactive mode (manual control)")
    
    try:
        mode = input("[MAIN] Enter choice (1 or 2): ").strip()
        
        if mode == "1":
            # Start automatic test scenario thread
            test_thread = threading.Thread(target=test_scenario_thread, args=(service,), daemon=True)
            test_thread.start()
            print(f"[MAIN] {datetime.datetime.now().strftime('%H:%M:%S.%f')[:-3]} ✅ Automatic test thread started")
        elif mode == "2":
            # Start interactive mode thread
            interactive_thread = threading.Thread(target=interactive_mode, args=(service,), daemon=True)
            interactive_thread.start()
            print(f"[MAIN] {datetime.datetime.now().strftime('%H:%M:%S.%f')[:-3]} ✅ Interactive mode thread started")
        else:
            print(f"[MAIN] {datetime.datetime.now().strftime('%H:%M:%S.%f')[:-3]} ⚠️ Invalid choice, defaulting to automatic mode")
            test_thread = threading.Thread(target=test_scenario_thread, args=(service,), daemon=True)
            test_thread.start()
    except KeyboardInterrupt:
        mode = "1"  # Default to automatic
        test_thread = threading.Thread(target=test_scenario_thread, args=(service,), daemon=True)
        test_thread.start()
    
    # Run main loop
    try:
        loop = GLib.MainLoop()
        print(f"[MAIN] {datetime.datetime.now().strftime('%H:%M:%S.%f')[:-3]} 🏃 Service running - press Ctrl+C to stop")
        loop.run()
    except KeyboardInterrupt:
        print(f"\n[MAIN] {datetime.datetime.now().strftime('%H:%M:%S.%f')[:-3]} 🛑 Service stopped by user")
    except Exception as e:
        print(f"[MAIN] {datetime.datetime.now().strftime('%H:%M:%S.%f')[:-3]} ❌ Error: {e}")
