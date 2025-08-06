from piracer.vehicles import PiRacerPro, PiRacerStandard
from piracer.gamepads import ShanWanGamepad

if __name__ == '__main__':

    shanwan_gamepad = ShanWanGamepad()
    #piracer = PiRacerPro()
    piracer = PiRacerStandard()

    while True:
        gamepad_input = shanwan_gamepad.read_data()

        #throttle = -gamepad_input.analog_stick_right.x * 0.5
        steering = -gamepad_input.analog_stick_left.x
        if gamepad_input.button_a == 1:
            throttle = gamepad_input.button_a * 0.5
        else:
            throttle = -gamepad_input.button_b * 0.5

        print(f'throttle ={throttle}, steering={steering}')

        piracer.set_throttle_percent(throttle)
        piracer.set_steering_percent(steering)

	 
