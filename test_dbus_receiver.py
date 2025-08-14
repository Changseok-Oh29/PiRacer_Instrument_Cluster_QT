#!/usr/bin/env python3
import dbus
import dbus.mainloop.glib
from gi.repository import GLib
import datetime

def on_data_received(data_json):
    print(f"[RECEIVER] {datetime.datetime.now().strftime('%H:%M:%S.%f')[:-3]} 📨 Received signal: {data_json}")

if __name__ == "__main__":
    print(f"[TEST] {datetime.datetime.now().strftime('%H:%M:%S.%f')[:-3]} 🧪 Testing DBus signal reception...")
    
    # Set up DBus main loop
    dbus.mainloop.glib.DBusGMainLoop(set_as_default=True)
    
    try:
        # Connect to the signal
        bus = dbus.SessionBus()
        bus.add_signal_receiver(
            on_data_received,
            dbus_interface="org.team7.IC.Interface",
            signal_name="DataReceived",
            bus_name="org.team7.IC",
            path="/CarInformation"
        )
        
        print(f"[TEST] {datetime.datetime.now().strftime('%H:%M:%S.%f')[:-3]} ✅ Connected to DBus signal")
        print(f"[TEST] Waiting for battery data signals...")
        
        # Run main loop
        loop = GLib.MainLoop()
        loop.run()
        
    except Exception as e:
        print(f"[TEST] {datetime.datetime.now().strftime('%H:%M:%S.%f')[:-3]} ❌ Error: {e}")
