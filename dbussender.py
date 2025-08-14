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

def get_battery(piracer):
    v = piracer.get_battery_voltage() / 3
    print(f"[SENDER] {datetime.datetime.now().strftime('%H:%M:%S.%f')[:-3]} Raw voltage: {v:.3f}V")

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

    def _emit_data_signal(self):
        """Emit signal with both battery and charging data"""
        data = {
            "battery_capacity": self.battery_level,
            "charging_current": self.current_ma
        }
        json_data = json.dumps(data)
        print(f"[TEST_SERVICE] {datetime.datetime.now().strftime('%H:%M:%S.%f')[:-3]} 📤 Emitting DataReceived signal: {json_data}")
        self.DataReceived(json_data)


    @dbus.service.signal("org.team7.IC.Interface", signature='s')
    def DataReceived(self, data_json):
        """Signal emitted when battery data is updated"""
        pass

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
