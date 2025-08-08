#!/usr/bin/env python3

import dbus
import dbus.service
import dbus.mainloop.glib
from gi.repository import GLib
import json
import time
import threading

class DataSender(dbus.service.Object):
    """
    D-Bus service to send arbitrary data to Qt application
    """
    
    def __init__(self):
        # Set up D-Bus main loop
        dbus.mainloop.glib.DBusGMainLoop(set_as_default=True)
        
        # Connect to session bus
        self.bus = dbus.# The `SessionBus` in the
        # provided Python code
        # snippet is used to connect
        # to the D-Bus session bus.
        # The D-Bus session bus is a
        # communication channel that
        # allows communication
        # between different
        # applications running
        # within the same user
        # session.
        SessionBus()
        
        # Create service name
        self.bus_name = dbus.service.BusName("org.team7.IC", self.bus)
        
        # Initialize the service object
        super().__init__(self.bus_name, "/CarInformation")
        
        print("D-Bus service started: org.team7.IC")
    
    @dbus.service.method("org.team7.IC.Interface",
                        in_signature='s', out_signature='b')
    def SendData(self, data_json):
        """
        Send arbitrary data as JSON string
        """
        try:
            data = json.loads(data_json)
            print(f"Sending data: {data}")
            
            # Emit signal with the data
            self.DataReceived(data_json)
            return True
        except Exception as e:
            print(f"Error sending data: {e}")
            return False
    
    @dbus.service.signal("org.team7.IC.Interface",
                        signature='s')
    def DataReceived(self, data_json):
        """
        Signal emitted when data is received
        """
        pass

def send_sample_data(sender_service):
    """
    Function to send sample data periodically
    """
    while True:
        # Battery capacity data
        battery_data = {
            "battery_capacity": 50
        }
        
        # Convert to JSON and send via signal
        json_data = json.dumps(battery_data)
        print(f"Emitting battery data: {battery_data}")
        
        # Emit signal directly
        sender_service.DataReceived(json_data)

        time.sleep(1)  # Send data every second

def main():
    # Create the data sender service
    sender_service = DataSender()
    
    # Start sending sample data in a separate thread
    data_thread = threading.Thread(target=send_sample_data, args=(sender_service,), daemon=True)
    data_thread.start()
    
    # Run the main loop
    loop = GLib.MainLoop()
    
    try:
        print("Starting data sender service...")
        print("Press Ctrl+C to stop")
        loop.run()
    except KeyboardInterrupt:
        print("\nStopping service...")
        loop.quit()

if __name__ == "__main__":
    main()