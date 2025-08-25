import dbus
import dbus.service
import dbus.mainloop.glib
from gi.repository import GLib
import datetime
import threading
import json
from piracer.vehicles import PiRacerStandard
from collections import deque
import time

# Initialize global variable for voltage filtering
filtered_voltage = 0.0

def get_battery(piracer):
    global filtered_voltage
    alpha = 0.1
    raw_voltage = piracer.get_battery_voltage()
    filtered_voltage = (alpha * raw_voltage) + ((1 - alpha) * filtered_voltage)
    v = filtered_voltage / 3

    print(f"[SENDER] {datetime.datetime.now().strftime('%H:%M:%S.%f')[:-3]} voltage: {v:.3f}V")

    if v > 4.2:
        battery_percentage = 100
    elif v >= 4.1:
        battery_percentage = 87 + ((v - 4.1) / (4.2 - 4.1)) * (100 - 87)
    elif v >= 4.0:
        battery_percentage = 75 + ((v - 4.0) / (4.1 - 4.0)) * (87 - 75)
    elif v >= 3.9:
        battery_percentage = 55 + ((v - 3.9) / (4.0 - 3.9)) * (75 - 55)
    elif v >= 3.8:
        battery_percentage = 30 + ((v - 3.8) / (3.9 - 3.8)) * (55 - 30)
    elif v >= 3.6:
        battery_percentage = 0 + ((v - 3.6) / (3.8 - 3.6)) * (30 - 0)
    else:
        battery_percentage = 0

    print(f"[SENDER] {datetime.datetime.now().strftime('%H:%M:%S.%f')[:-3]} Calculated percentage: {battery_percentage:.1f}%")
    return battery_percentage

class CarInformationService(dbus.service.Object):
    def __init__(self):
        bus_name = dbus.service.BusName("org.team7.IC", bus=dbus.SessionBus())
        dbus.service.Object.__init__(self, bus_name, "/CarInformation")
        self.battery_level = 0.0
        self.current_ma = 0.0
        # Turn signal states
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

        # Emit signal for Qt to receive
        self._emit_data_signal()

    @dbus.service.method("org.team7.IC.Interface", in_signature='', out_signature='d')
    def getBattery(self):
        print(f"[SERVICE] {datetime.datetime.now().strftime('%H:%M:%S.%f')[:-3]} 📊 Battery level requested: {self.battery_level:.1f}%")
        return self.battery_level

    @dbus.service.method("org.team7.IC.Interface", in_signature='bb', out_signature='')
    def setTurnSignals(self, left_active, right_active):
        """Set turn signal states"""
        self.left_turn_signal = bool(left_active)
        self.right_turn_signal = bool(right_active)
        print(f"[SERVICE] {datetime.datetime.now().strftime('%H:%M:%S.%f')[:-3]} 🔄 Turn signals set - Left: {self.left_turn_signal}, Right: {self.right_turn_signal}")
        self._emit_data_signal()

    @dbus.service.method("org.team7.IC.Interface", in_signature='', out_signature='bb')
    def getTurnSignals(self):
        """Get current turn signal states"""
        print(f"[SERVICE] {datetime.datetime.now().strftime('%H:%M:%S.%f')[:-3]} 📊 Turn signals requested - Left: {self.left_turn_signal}, Right: {self.right_turn_signal}")
        return self.left_turn_signal, self.right_turn_signal

    def _emit_data_signal(self):
        """Emit signal with battery, charging and turn signal data"""
        data = {
            "battery_capacity": self.battery_level,
            "charging_current": self.current_ma,
            "left_turn_signal": self.left_turn_signal,
            "right_turn_signal": self.right_turn_signal
        }
        json_data = json.dumps(data)
        print(f"[TEST_SERVICE] {datetime.datetime.now().strftime('%H:%M:%S.%f')[:-3]} 📤 Emitting DataReceived signal: {json_data}")
        self.DataReceived(json_data)


    @dbus.service.signal("org.team7.IC.Interface", signature='s')
    def DataReceived(self, data_json):
        """Signal emitted when battery data is updated"""
        pass

class TurnSignalClient:
    """Client class for sending turn signal data to the DBus service"""
    def __init__(self):
        self.bus = dbus.SessionBus()
        self.service_name = "org.team7.IC"
        self.object_path = "/CarInformation"
        self.interface_name = "org.team7.IC.Interface"
        
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
                
                print(f"[CLIENT] ✓ Connected to DBus service: {self.service_name}")
                self.connected = True
                return True
                
            except dbus.DBusException as e:
                self.retry_count += 1
                print(f"[CLIENT] DBus connection attempt {self.retry_count}/{self.max_retries} failed: {e}")
                
                if self.retry_count < self.max_retries:
                    print("[CLIENT] Retrying in 2 seconds...")
                    time.sleep(2)
                else:
                    print("[CLIENT] ❌ Failed to connect to DBus service after maximum retries")
                    return False
        
        return self.connected
        
    def send_turn_signal(self, left_active, right_active):
        """
        Send turn signal states to the dashboard service
        
        Args:
            left_active (bool): Left turn signal state
            right_active (bool): Right turn signal state
        """
        if not self.connected:
            print("[CLIENT] ❌ Not connected to DBus service, attempting reconnection...")
            if not self._connect_to_service():
                return False
                
        try:
            # Send turn signal data via DBus
            self.interface.setTurnSignals(
                dbus.Boolean(left_active),
                dbus.Boolean(right_active)
            )
            
            print(f"[CLIENT] ✓ Turn signals sent - Left: {left_active}, Right: {right_active}")
            return True
            
        except dbus.DBusException as e:
            print(f"[CLIENT] ❌ DBus send error: {e}")
            self.connected = False
            return False

def battery_sender_thread(piracer, service_instance):
    """Thread function to continuously read battery and send via DBus"""
    list_data = deque([0.0] * 100)

    # Wait a bit for service to initialize
    time.sleep(2)
    print(f"[SENDER] {datetime.datetime.now().strftime('%H:%M:%S.%f')[:-3]} 🔄 Starting data transmission loop...")

    while True:
        list_data.popleft()
        start_time = time.time()

        try:
            battery_now = get_battery(piracer)
            list_data.append(battery_now)
            battery = max(list_data)

            # Call service method directly to avoid D-Bus self-call issues
            service_instance.setBattery(float(battery))
            print(f"[SENDER] {datetime.datetime.now().strftime('%H:%M:%S.%f')[:-3]} 📤 Sent to service: {battery:.1f}%")

        except Exception as e:
            print(f"[SENDER] {datetime.datetime.now().strftime('%H:%M:%S.%f')[:-3]} ❌ Error: {e}")

        current_mA = piracer.get_battery_current()
        service_instance.setCurrent(float(current_mA))
        time.sleep(0.01)
        end_time = time.time()
        processing_time = (end_time - start_time) * 1000  # Convert to milliseconds
        print(f"[SENDER] {datetime.datetime.now().strftime('%H:%M:%S.%f')[:-3]} ⏱️ Processing time: {processing_time:.2f}ms")

if __name__ == "__main__":
    print(f"[MAIN] {datetime.datetime.now().strftime('%H:%M:%S.%f')[:-3]} 🚀 Starting DBus service and battery sender...")

    # Initialize PiRacer
    try:
        piracer = PiRacerStandard()
        print(f"[MAIN] {datetime.datetime.now().strftime('%H:%M:%S.%f')[:-3]} ✅ PiRacer initialized")
    except Exception as e:
        print(f"[MAIN] {datetime.datetime.now().strftime('%H:%M:%S.%f')[:-3]} ❌ Failed to initialize PiRacer: {e}")
        exit(1)

    # Set up DBus main loop
    dbus.mainloop.glib.DBusGMainLoop(set_as_default=True)

    # Start DBus service
    try:
        service = CarInformationService()
        print(f"[MAIN] {datetime.datetime.now().strftime('%H:%M:%S.%f')[:-3]} ✅ DBus service started")
    except Exception as e:
        print(f"[MAIN] {datetime.datetime.now().strftime('%H:%M:%S.%f')[:-3]} ❌ Failed to start DBus service: {e}")
        exit(1)

    # Start battery sender thread
    sender_thread = threading.Thread(target=battery_sender_thread, args=(piracer, service), daemon=True)
    sender_thread.start()
    print(f"[MAIN] {datetime.datetime.now().strftime('%H:%M:%S.%f')[:-3]} ✅ Battery sender thread started")

    # Run main loop
    try:
        loop = GLib.MainLoop()
        print(f"[MAIN] {datetime.datetime.now().strftime('%H:%M:%S.%f')[:-3]} 💡 Service running - press Ctrl+C to stop")
        loop.run()
    except KeyboardInterrupt:
        print(f"[MAIN] {datetime.datetime.now().strftime('%H:%M:%S.%f')[:-3]} 🛑 Service stopped by user")
    except Exception as e:
        print(f"[MAIN] {datetime.datetime.now().strftime('%H:%M:%S.%f')[:-3]} ❌ Error: {e}")
