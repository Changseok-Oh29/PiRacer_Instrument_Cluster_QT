import dbus

from piracer.vehicles import PiRacerStandard
from collections import deque

import time

def get_battery():
    v = piracer.get_battery_voltage() / 3
    print(v)
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
        
    return battery_percentage

if __name__ == "__main__":
    piracer = PiRacerStandard()
    list = deque([0]*100)
    bus = dbus.SystemBus()
    service = bus.get_object("org.team7.IC", "/CarInformation")
    car_interface = dbus.Interface(service, "org.team7.IC.CarInformation")
    
    while True:
        list.popleft()
        start_time = time.time()
        battery_now = get_battery()
        list.append(battery_now)
        battery = max(list)
        car_interface.setBattery(float(battery))
        time.sleep(0.01)
        end_time = time.time()
        print("time: ", end_time - start_time)