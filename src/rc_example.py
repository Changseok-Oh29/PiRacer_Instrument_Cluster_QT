from piracer.vehicles import PiRacerPro, PiRacerStandard
from piracer.gamepads import ShanWanGamepad
from dbussender import TurnSignalClient
import time

if __name__ == '__main__':

    shanwan_gamepad = ShanWanGamepad()
    #piracer = PiRacerPro()
    piracer = PiRacerStandard()
    
    # DBus 방향지시등 클라이언트 초기화
    try:
        turn_signal_client = TurnSignalClient()
        print("✅ Turn signal client initialized")
    except Exception as e:
        print(f"❌ Failed to initialize turn signal client: {e}")
        turn_signal_client = None
    
    # 모드 상태 변수
    drive_mode = False   # False: 정지, True: 전진 모드 활성
    reverse_mode = False # False: 정지, True: 후진 모드 활성
    
    # 방향지시등 상태 변수
    left_turn_signal = False
    right_turn_signal = False
    
    # 버튼 눌림 상태 추적 (토글용)
    prev_button_a = 0
    prev_button_b = 0
    prev_button_l1 = 0
    prev_button_r1 = 0

    throttle_multiplier = 0.5

    print("🚗 PiRacer RC Example with Turn Signals")
    print("Controls:")
    print("- A button: Toggle drive mode")
    print("- B button: Toggle reverse mode") 
    print("- L1 button: Toggle left turn signal")
    print("- R1 button: Toggle right turn signal")
    print("- Left analog stick: Steering (also turns off turn signals)")
    print("- Right analog stick: Throttle")
    print("Starting main loop...")

    while True:
        try:
            gamepad_input = shanwan_gamepad.read_data()

            steering = -gamepad_input.analog_stick_left.x
            
            # A 버튼: 전진 모드 토글 (한 번 누르면 전진 모드 ON/OFF)
            if gamepad_input.button_a == 1 and prev_button_a == 0:  # 버튼이 방금 눌림
                drive_mode = not drive_mode  # 전진 모드 토글
                if drive_mode:
                    reverse_mode = False  # 전진 모드가 켜지면 후진 모드는 끔
                print(f"Drive mode: {'ON' if drive_mode else 'OFF'}")
            
            # B 버튼: 후진 모드 토글 (한 번 누르면 후진 모드 ON/OFF)
            if gamepad_input.button_b == 1 and prev_button_b == 0:  # 버튼이 방금 눌림
                reverse_mode = not reverse_mode  # 후진 모드 토글
                if reverse_mode:
                    drive_mode = False  # 후진 모드가 켜지면 전진 모드는 끔
                print(f"Reverse mode: {'ON' if reverse_mode else 'OFF'}")
            
            # L1 버튼: 좌측 방향지시등 토글
            if gamepad_input.button_l1 == 1 and prev_button_l1 == 0:  # 버튼이 방금 눌림
                left_turn_signal = not left_turn_signal  # 좌측 방향지시등 토글
                if left_turn_signal:
                    right_turn_signal = False  # 좌측이 켜지면 우측은 끔
                print(f"Left turn signal: {'ON' if left_turn_signal else 'OFF'}")
            
            # R1 버튼: 우측 방향지시등 토글
            if gamepad_input.button_r1 == 1 and prev_button_r1 == 0:  # 버튼이 방금 눌림
                right_turn_signal = not right_turn_signal  # 우측 방향지시등 토글
                if right_turn_signal:
                    left_turn_signal = False  # 우측이 켜지면 좌측은 끔
                print(f"Right turn signal: {'ON' if right_turn_signal else 'OFF'}")
            
            # 아날로그 스틱으로 방향지시등 끄기
            stick_threshold = 0.3  # 스틱 움직임 감지 임계값
            if abs(gamepad_input.analog_stick_left.x) > stick_threshold:
                if gamepad_input.analog_stick_left.x < 0 and right_turn_signal:
                    # 오른쪽으로 스티어링하면 우측 방향지시등 끄기
                    right_turn_signal = False
                    print("Right turn signal OFF (steering right)")
                elif gamepad_input.analog_stick_left.x > 0 and left_turn_signal:
                    # 왼쪽으로 스티어링하면 좌측 방향지시등 끄기  
                    left_turn_signal = False
                    print("Left turn signal OFF (steering left)")
            
            # 이전 버튼 상태 저장
            prev_button_a = gamepad_input.button_a
            prev_button_b = gamepad_input.button_b
            prev_button_l1 = gamepad_input.button_l1
            prev_button_r1 = gamepad_input.button_r1
            
            throttle_input = gamepad_input.analog_stick_right.y

            # 선택된 모드에 따른 스로틀 제어
            if drive_mode and throttle_input > 0:
                # 전진 모드: analog_stick_right.y로 전진 제어
                throttle = throttle_input * throttle_multiplier
                mode_str = "DRIVE"
            elif reverse_mode and throttle_input > 0:
                # 후진 모드: analog_stick_right.y로 후진 제어
                throttle = - throttle_input * throttle_multiplier
                mode_str = "REVERSE"
            else:
                # 모든 모드가 꺼져있으면 정지
                throttle = 0.0
                mode_str = "STOP"

            print(f'Mode: {mode_str}, throttle={throttle:.2f}, steering={steering:.2f}, L:{left_turn_signal}, R:{right_turn_signal}')

            # PiRacer 제어
            piracer.set_throttle_percent(throttle)
            piracer.set_steering_percent(steering)
            
            # DBus로 방향지시등 상태 전송
            if turn_signal_client and turn_signal_client.connected:
                try:
                    turn_signal_client.send_turn_signal(left_turn_signal, right_turn_signal)
                except Exception as e:
                    print(f"❌ Turn signal send error: {e}")
            
            # 짧은 지연 (CPU 사용량 줄이기)
            time.sleep(0.01)
            
        except KeyboardInterrupt:
            print("\n🛑 Stopping RC controller...")
            # 정지 상태로 설정
            piracer.set_throttle_percent(0.0)
            piracer.set_steering_percent(0.0)
            # 방향지시등 끄기
            if turn_signal_client and turn_signal_client.connected:
                try:
                    turn_signal_client.send_turn_signal(False, False)
                    print("Turn signals turned off")
                except:
                    pass
            break
        except Exception as e:
            print(f"❌ Error in main loop: {e}")
            time.sleep(0.1)  # 오류 시 잠시 대기