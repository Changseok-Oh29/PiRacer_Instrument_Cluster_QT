#!/bin/bash

# Test script to simulate CAN data for the dashboard
# This script sends test CAN frames to the can10 interface

# Check if can10 interface exists
if ! ip link show can10 >/dev/null 2>&1; then
    echo "CAN interface can10 not found. Creating virtual CAN interface..."
    sudo modprobe vcan
    sudo ip link add dev can10 type vcan
    sudo ip link set up can10
    echo "Virtual CAN interface can10 created and enabled."
fi

echo "Sending test CAN data to can10..."
echo "Use Ctrl+C to stop"

# Function to send CAN frame
send_can_frame() {
    local speed_int=$1
    local speed_frac=$2
    local rpm_int=$3
    local rpm_frac=$4
    
    # Convert integers to hex bytes
    local speed_high=$(printf "%02x" $((speed_int >> 8)))
    local speed_low=$(printf "%02x" $((speed_int & 0xFF)))
    local speed_frac_hex=$(printf "%02x" $speed_frac)
    local rpm_high=$(printf "%02x" $((rpm_int >> 8)))
    local rpm_low=$(printf "%02x" $((rpm_int & 0xFF)))
    local rpm_frac_hex=$(printf "%02x" $rpm_frac)
    
    # Send CAN frame with ID 0x123
    cansend can10 123#${speed_high}${speed_low}${speed_frac_hex}${rpm_high}${rpm_low}${rpm_frac_hex}
}

# Simulate realistic vehicle data
counter=0
while true; do
    # Generate realistic speed and RPM values
    speed_base=$((30 + (counter % 60)))  # Speed between 30-90
    speed_frac=$((RANDOM % 100))         # Fractional part 0-99
    
    rpm_base=$((1000 + speed_base * 20 + (RANDOM % 500))) # RPM based on speed
    rpm_frac=$((RANDOM % 100))           # Fractional part 0-99
    
    # Send the frame
    send_can_frame $speed_base $speed_frac $rpm_base $rpm_frac
    
    echo "Sent: Speed=${speed_base}.${speed_frac} cm/s, RPM=${rpm_base}.${rpm_frac}"
    
    # Wait 500ms before next frame
    sleep 0.5
    
    ((counter++))
done
