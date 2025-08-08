import dbus
import datetime

from piracer.vehicles import PiRacerStandard
from collections import deque

import time

def get_battery():
    v = piracer.get_battery_voltage() / 3
    print(f"[SENDER] {datetime.datetime.now().strftime('%H:%M:%S.%f')[:-3]} Raw voltage: {v:.3f}V")
    if v > 4.2:
        battery_percentage = 100
    elif v>=4.1:
        battery_percentage = 87 + ((v - 4.1) / (4.2 - 4.1)) * (100 - 87)
    elif v>=4.0:
        battery_percentage = 75 + ((v - 4.0) / (4.1 - 4.0)) * (87 - 75)
    elif v>=3.9:
        battery_percentage = 55 + ((v - 3.9) / (4.0 - 3.9)) * (75 - 55)
    elif v>=3.8:
        battery_percentage = 30 + ((v - 3.8) / (3.9 - 3.8)) * (55 - 30)
    elif v>=3.6:
        battery_percentage = 0 + ((v - 3.6) / (3.8 - 3.6)) * (30 - 0)
    else:
        battery_percentage = 0
    
    print(f"[SENDER] {datetime.datetime.now().strftime('%H:%M:%S.%f')[:-3]} Calculated percentage: {battery_percentage:.1f}%")
    return battery_percentage

if __name__ == "__main__":
    print(f"[SENDER] {datetime.datetime.now().strftime('%H:%M:%S.%f')[:-3]} 🚀 Starting DBus sender...")
    
    try:
        piracer = PiRacerStandard()
        print(f"[SENDER] {datetime.datetime.now().strftime('%H:%M:%S.%f')[:-3]} ✅ PiRacer initialized")
    except Exception as e:
        print(f"[SENDER] {datetime.datetime.now().strftime('%H:%M:%S.%f')[:-3]} ❌ Failed to initialize PiRacer: {e}")
        
    list = deque([0]*100)
    
    try:
        bus = dbus.SystemBus()
        service = bus.get_object("org.team7.IC", "/CarInformation")
        car_interface = dbus.Interface(service, "org.team7.IC.CarInformation")
        print(f"[SENDER] {datetime.datetime.now().strftime('%H:%M:%S.%f')[:-3]} ✅ Connected to DBus service")
    except Exception as e:
        print(f"[SENDER] {datetime.datetime.now().strftime('%H:%M:%S.%f')[:-3]} ❌ Failed to connect to DBus: {e}")
        exit(1)
    
    print(f"[SENDER] {datetime.datetime.now().strftime('%H:%M:%S.%f')[:-3]} 🔄 Starting data transmission loop...")
    
    while True:
        list.popleft()
        start_time = time.time()
        
        try:
            battery_now = get_battery()
            list.append(battery_now)
            battery = max(list)
            
            # Send to DBus
            car_interface.setBattery(float(battery))
            print(f"[SENDER] {datetime.datetime.now().strftime('%H:%M:%S.%f')[:-3]} 📤 Sent to DBus: {battery:.1f}%")
            
        except Exception as e:
            print(f"[SENDER] {datetime.datetime.now().strftime('%H:%M:%S.%f')[:-3]} ❌ Error: {e}")
        
        time.sleep(0.01)
        end_time = time.time()
        processing_time = (end_time - start_time) * 1000  # Convert to milliseconds
        print(f"[SENDER] {datetime.datetime.now().strftime('%H:%M:%S.%f')[:-3]} ⏱️ Processing time: {processing_time:.2f}ms")