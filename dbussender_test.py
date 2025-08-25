#!/usr/bin/env python3
"""
Test version of dbussender.py that works without piracer hardware
Simulates battery and charging current data for testing
"""
import dbus
import dbus.service
import dbus.mainloop.glib
from gi.repository import GLib
import datetime
import threading
import json
import time
import math

class CarInformationService(dbus.service.Object):
    def __init__(self):
        bus_name = dbus.service.BusName("org.team7.IC", bus=dbus.SessionBus())
        dbus.service.Object.__init__(self, bus_name, "/CarInformation")
        self.battery_level = 0.0
        self.current_ma = 0.0
        self.left_turn_signal = False
        self.right_turn_signal = False
        print(f"[SERVICE] {datetime.datetime.now().strftime('%H:%M:%S.%f')[:-3]} ✅ DBus service org.team7.IC started")

    @dbus.service.method("org.team7.IC.Interface", in_signature='d', out_signature='')
    def setCurrent(self, current_ma):
        self.current_ma = float(current_ma)
        print(f"[SERVICE] current received: {self.current_ma:.1f}mA")
        self._emit_data_signal()

    @dbus.service.method("org.team7.IC.Interface", in_signature='d', out_signature='')
    def setBattery(self, battery_level):
        self.battery_level = float(battery_level)
        print(f"[SERVICE] {datetime.datetime.now().strftime('%H:%M:%S.%f')[:-3]} 🔋 Battery level received: {self.battery_level:.1f}%")
        self._emit_data_signal()

    @dbus.service.method("org.team7.IC.Interface", in_signature='', out_signature='d')
    def getBattery(self):
        print(f"[SERVICE] {datetime.datetime.now().strftime('%H:%M:%S.%f')[:-3]} 📊 Battery level requested: {self.battery_level:.1f}%")
        return self.battery_level

    def _emit_data_signal(self):
        """Emit signal with both battery and charging data"""
        data = {
            "battery_capacity": self.battery_level,
            "charging_current": self.current_ma
        }
        json_data = json.dumps(data)
        print(f"[SERVICE] {datetime.datetime.now().strftime('%H:%M:%S.%f')[:-3]} 📤 Emitting DataReceived signal: {json_data}")
        self.DataReceived(json_data)

    @dbus.service.signal("org.team7.IC.Interface", signature='s')
    def DataReceived(self, data_json):
        """Signal emitted when data is updated"""
        pass

def simulated_data_thread(service_instance):
    """Thread function to simulate battery and charging current data"""
    time.sleep(2)
    print(f"[SIMULATOR] {datetime.datetime.now().strftime('%H:%M:%S.%f')[:-3]} 🔄 Starting simulation loop...")
    
    start_time = time.time()
    
    while True:
        try:
            elapsed = time.time() - start_time
            
            # Simulate slowly changing battery (60 seconds full cycle)
            battery_cycle = (elapsed % 60.0) / 60.0
            battery_percentage = 50 + 40 * math.sin(2 * math.pi * battery_cycle)
            
            # Simulate charging current that varies (30 seconds cycle)
            current_cycle = (elapsed % 30.0) / 30.0
            charging_current = 500 + 1200 * abs(math.sin(2 * math.pi * current_cycle))
            
            # Update service
            service_instance.setBattery(float(battery_percentage))
            service_instance.setCurrent(float(charging_current))
            
            print(f"[SIMULATOR] Battery: {battery_percentage:.1f}%, Current: {charging_current:.1f}mA")
            
        except Exception as e:
            print(f"[SIMULATOR] ❌ Error: {e}")
        
        time.sleep(1.0)  # Update every second

if __name__ == "__main__":
    print(f"[MAIN] {datetime.datetime.now().strftime('%H:%M:%S.%f')[:-3]} 🚀 Starting TEST DBus service...")
    print(f"[MAIN] This version simulates battery and charging data without piracer hardware")
    
    # Set up DBus main loop
    dbus.mainloop.glib.DBusGMainLoop(set_as_default=True)
    
    # Start DBus service
    try:
        service = CarInformationService()
        print(f"[MAIN] {datetime.datetime.now().strftime('%H:%M:%S.%f')[:-3]} ✅ DBus service started")
    except Exception as e:
        print(f"[MAIN] {datetime.datetime.now().strftime('%H:%M:%S.%f')[:-3]} ❌ Failed to start DBus service: {e}")
        exit(1)
    
    # Start simulation thread
    sim_thread = threading.Thread(target=simulated_data_thread, args=(service,), daemon=True)
    sim_thread.start()
    print(f"[MAIN] {datetime.datetime.now().strftime('%H:%M:%S.%f')[:-3]} ✅ Simulation thread started")
    
    # Run main loop
    try:
        loop = GLib.MainLoop()
        print(f"[MAIN] {datetime.datetime.now().strftime('%H:%M:%S.%f')[:-3]} 💡 Service running - press Ctrl+C to stop")
        print(f"[MAIN] Battery will vary from 10% to 90%, Current will vary from 500mA to 1700mA")
        loop.run()
    except KeyboardInterrupt:
        print(f"[MAIN] {datetime.datetime.now().strftime('%H:%M:%S.%f')[:-3]} 🛑 Service stopped by user")
    except Exception as e:
        print(f"[MAIN] {datetime.datetime.now().strftime('%H:%M:%S.%f')[:-3]} ❌ Error: {e}")
