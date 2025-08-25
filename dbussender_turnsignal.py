#!/usr/bin/env python3
"""
DBus Turn Signal Sender
Sends turn signal states from controller to Qt application
"""

import dbus
import dbus.service
from dbus.mainloop.glib import DBusGMainLoop
from gi.repository import GLib
import threading
import time

class TurnSignalSender:
    def __init__(self):
        """Initialize DBus connection for sending turn signal data"""
        print("Initializing Turn Signal DBus Sender...")
        
        # Setup DBus main loop
        DBusGMainLoop(set_as_default=True)
        
        # Connect to session bus
        self.bus = dbus.SessionBus()
        self.service_name = 'com.example.Dashboard'
        self.object_path = '/Dashboard'
        self.interface_name = 'com.example.Dashboard'
        
        # Connection state
        self.connected = False
        self.retry_count = 0
        self.max_retries = 10
        
        # Connect to service
        self._connect_to_service()
        
    def _connect_to_service(self):
        """Connect to the DBus service with retry logic"""
        while self.retry_count < self.max_retries and not self.connected:
            try:
                # Get the service object
                self.service_object = self.bus.get_object(self.service_name, self.object_path)
                self.interface = dbus.Interface(self.service_object, self.interface_name)
                
                print(f"✓ Connected to DBus service: {self.service_name}")
                self.connected = True
                return True
                
            except dbus.DBusException as e:
                self.retry_count += 1
                print(f"DBus connection attempt {self.retry_count}/{self.max_retries} failed: {e}")
                
                if self.retry_count < self.max_retries:
                    print("Retrying in 2 seconds...")
                    time.sleep(2)
                else:
                    print("❌ Failed to connect to DBus service after maximum retries")
                    return False
        
        return self.connected
        
    def send_turn_signal(self, left_active, right_active):
        """
        Send turn signal states to the dashboard
        
        Args:
            left_active (bool): Left turn signal state
            right_active (bool): Right turn signal state
        """
        if not self.connected:
            print("❌ Not connected to DBus service, attempting reconnection...")
            if not self._connect_to_service():
                return False
                
        try:
            # Send turn signal data via DBus
            self.interface.updateTurnSignals(
                dbus.Boolean(left_active),
                dbus.Boolean(right_active)
            )
            
            print(f"✓ Turn signals sent - Left: {left_active}, Right: {right_active}")
            return True
            
        except dbus.DBusException as e:
            print(f"❌ DBus send error: {e}")
            self.connected = False
            return False
            
    def send_battery_data(self, battery_level, charging_current=0.0):
        """
        Send battery data to the dashboard (backup method)
        
        Args:
            battery_level (float): Battery percentage (0-100)
            charging_current (float): Charging current in mA
        """
        if not self.connected:
            if not self._connect_to_service():
                return False
                
        try:
            self.interface.updateBatteryData(
                dbus.Double(battery_level),
                dbus.Double(charging_current)
            )
            
            print(f"✓ Battery data sent - Level: {battery_level}%, Current: {charging_current}mA")
            return True
            
        except dbus.DBusException as e:
            print(f"❌ Battery data send error: {e}")
            self.connected = False
            return False

# Test function
def test_turn_signal_sender():
    """Test the turn signal sender functionality"""
    print("Testing Turn Signal Sender...")
    
    sender = TurnSignalSender()
    
    if not sender.connected:
        print("Cannot test - no DBus connection")
        return
        
    # Test sequence
    test_sequence = [
        (True, False),   # Left on
        (False, False),  # Both off
        (False, True),   # Right on
        (False, False),  # Both off
        (True, False),   # Left on again
        (False, False),  # Both off
    ]
    
    for left, right in test_sequence:
        print(f"Testing: Left={left}, Right={right}")
        sender.send_turn_signal(left, right)
        time.sleep(1)
        
    print("Test completed!")

if __name__ == "__main__":
    test_turn_signal_sender()
