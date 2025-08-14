#!/usr/bin/env python3
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
        print(f"[SERVICE] {datetime.datetime.now().strftime('%H:%M:%S.%f')[:-3]} ✅ DBus service org.team7.IC started")

    @dbus.service.method("org.team7.IC.Interface", in_signature='d', out_signature='')
    def setBattery(self, battery_level):
        self.battery_level = float(battery_level)
        print(f"[SERVICE] {datetime.datetime.now().strftime('%H:%M:%S.%f')[:-3]} 🔋 Battery level received: {self.battery_level:.1f}%")
        
        # Emit signal for Qt to receive
        battery_data = {
            "battery_capacity": self.battery_level
        }
        json_data = json.dumps(battery_data)
        print(f"[SERVICE] {datetime.datetime.now().strftime('%H:%M:%S.%f')[:-3]} 📤 Emitting DataReceived signal: {json_data}")
        self.DataReceived(json_data)

    @dbus.service.method("org.team7.IC.Interface", in_signature='', out_signature='d')
    def getBattery(self):
        print(f"[SERVICE] {datetime.datetime.now().strftime('%H:%M:%S.%f')[:-3]} 📊 Battery level requested: {self.battery_level:.1f}%")
        return self.battery_level
    
    @dbus.service.signal("org.team7.IC.Interface", signature='s')
    def DataReceived(self, data_json):
        """Signal emitted when battery data is updated"""
        pass

def simulated_battery_sender_thread(service_instance):
    """Thread function to simulate battery data and send via DBus"""
    
    # Wait a bit for service to initialize
    time.sleep(2)
    
    print(f"[SENDER] {datetime.datetime.now().strftime('%H:%M:%S.%f')[:-3]} 🔄 Starting simulated battery data transmission loop...")
    
    start_time = time.time()
    
    while True:
        try:
            # Simulate battery level that cycles from 100% to 0% over 60 seconds
            elapsed_time = time.time() - start_time
            cycle_time = 60.0  # 60 seconds for full cycle
            progress = (elapsed_time % cycle_time) / cycle_time
            
            # Create a sine wave that goes from 100 to 0 and back to 100
            battery_percentage = 50 + 50 * math.cos(2 * math.pi * progress)
            
            # Call service method directly to avoid D-Bus self-call issues
            service_instance.setBattery(float(battery_percentage))
            print(f"[SENDER] {datetime.datetime.now().strftime('%H:%M:%S.%f')[:-3]} 📤 Sent simulated battery: {battery_percentage:.1f}%")
            
        except Exception as e:
            print(f"[SENDER] {datetime.datetime.now().strftime('%H:%M:%S.%f')[:-3]} ❌ Error: {e}")
        
        time.sleep(1.0)  # Update every second for visible changes

if __name__ == "__main__":
    print(f"[MAIN] {datetime.datetime.now().strftime('%H:%M:%S.%f')[:-3]} 🚀 Starting TEST DBus service with simulated battery data...")
    
    # Set up DBus main loop
    dbus.mainloop.glib.DBusGMainLoop(set_as_default=True)
    
    # Start DBus service
    try:
        service = CarInformationService()
        print(f"[MAIN] {datetime.datetime.now().strftime('%H:%M:%S.%f')[:-3]} ✅ DBus service started")
    except Exception as e:
        print(f"[MAIN] {datetime.datetime.now().strftime('%H:%M:%S.%f')[:-3]} ❌ Failed to start DBus service: {e}")
        exit(1)
    
    # Start simulated battery sender thread
    sender_thread = threading.Thread(target=simulated_battery_sender_thread, args=(service,), daemon=True)
    sender_thread.start()
    print(f"[MAIN] {datetime.datetime.now().strftime('%H:%M:%S.%f')[:-3]} ✅ Simulated battery sender thread started")
    
    # Run main loop
    try:
        loop = GLib.MainLoop()
        print(f"[MAIN] {datetime.datetime.now().strftime('%H:%M:%S.%f')[:-3]} 🔄 Service running - press Ctrl+C to stop")
        print(f"[MAIN] Battery will cycle from 100% to 0% and back over 60 seconds")
        loop.run()
    except KeyboardInterrupt:
        print(f"[MAIN] {datetime.datetime.now().strftime('%H:%M:%S.%f')[:-3]} 🛑 Service stopped by user")
    except Exception as e:
        print(f"[MAIN] {datetime.datetime.now().strftime('%H:%M:%S.%f')[:-3]} ❌ Error: {e}")
