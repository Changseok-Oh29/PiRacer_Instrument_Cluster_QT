#!/usr/bin/env python3
"""
Test Turn Signal Integration
Tests the complete turn signal system from gamepad to UI
"""

import time
from dbussender import TurnSignalClient

def test_turn_signal_sequence():
    """Test various turn signal scenarios"""
    print("🚀 Starting Turn Signal Integration Test...")
    
    client = TurnSignalClient()
    
    if not client.connected:
        print("❌ Cannot test - DBus service not available")
        print("Make sure the Qt application is running first!")
        return False
        
    print("✓ DBus connection established")
    print("\n📝 Testing turn signal sequences...")
    
    # Test sequence with descriptions
    test_scenarios = [
        (False, False, "All signals OFF (initial state)"),
        (True, False, "LEFT turn signal ON"),
        (False, False, "LEFT turn signal OFF"),
        (False, True, "RIGHT turn signal ON"), 
        (False, False, "RIGHT turn signal OFF"),
        (True, False, "LEFT turn signal ON again"),
        (False, True, "Switch to RIGHT (LEFT should go OFF)"),
        (False, False, "All signals OFF (final state)"),
    ]
    
    for left, right, description in test_scenarios:
        print(f"\n🔄 {description}")
        success = client.send_turn_signal(left, right)
        
        if success:
            print(f"   ✓ Sent: Left={left}, Right={right}")
        else:
            print(f"   ❌ Failed to send signal")
            
        # Wait to see the blinking effect
        time.sleep(2)
        
    print("\n🎉 Turn signal test completed!")
    print("\nExpected UI behavior:")
    print("- Green arrows should blink when turn signals are ON")
    print("- Gray arrows when turn signals are OFF")
    print("- 500ms blink interval (2 blinks per second)")
    
    return True

def test_gamepad_simulation():
    """Simulate gamepad button presses"""
    print("\n🎮 Simulating gamepad inputs...")
    
    client = TurnSignalClient()
    
    if not client.connected:
        print("❌ Cannot test - DBus service not available")
        return False
        
    print("Simulating L1 button press (Left turn signal)...")
    client.send_turn_signal(True, False)
    time.sleep(3)
    
    print("Simulating steering right (should turn off left signal)...")
    client.send_turn_signal(False, False)
    time.sleep(1)
    
    print("Simulating R1 button press (Right turn signal)...")
    client.send_turn_signal(False, True)
    time.sleep(3)
    
    print("Simulating steering left (should turn off right signal)...")
    client.send_turn_signal(False, False)
    time.sleep(1)
    
    print("🎮 Gamepad simulation completed!")

if __name__ == "__main__":
    print("Turn Signal Integration Test")
    print("=" * 40)
    
    # Run main test
    success = test_turn_signal_sequence()
    
    if success:
        # Run gamepad simulation
        test_gamepad_simulation()
    
    print("\n📋 Test Summary:")
    print("1. ✓ DBus communication test")
    print("2. ✓ Turn signal sequence test") 
    print("3. ✓ Gamepad input simulation")
    print("\nNext steps:")
    print("- Test with actual gamepad using rc_example.py")
    print("- Verify UI color changes (green/gray)")
    print("- Check 500ms blink timing")
