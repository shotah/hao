# T-Bao K210 AI Engine - MaixPy Firmware
# =======================================
# Main K210 firmware for AI processing on T-Bao
# Handles: Face Recognition, Audio Processing, Image Analysis

import sensor
import image
import lcd
import KPU as kpu
import time
import utime
import gc
from machine import UART, Timer
from fpioa_manager import fm
import json

# Hardware Configuration
lcd.init()
lcd.rotation(2)  # Rotate display for T-Bao orientation
sensor.reset()
sensor.set_pixformat(sensor.RGB565)
sensor.set_framesize(sensor.QVGA)  # 320x240 for face detection
sensor.run(1)

# Communication with ESP32
fm.register(4, fm.fpioa.UART1_TX)
fm.register(5, fm.fpioa.UART1_RX)
uart = UART(UART.UART1, 115200, 8, 1, 0, timeout=1000, read_buf_len=4096)

# AI Models
face_detection_model = None
wake_word_model = None

# System State
class T_BaoState:
    def __init__(self):
        self.mode = "idle"  # idle, face_detection, audio_processing, image_analysis
        self.last_face_time = 0
        self.face_detected = False
        self.audio_active = False
        self.commands_queue = []

state = T_BaoState()

def init_ai_models():
    """Initialize AI models for face detection and audio processing"""
    global face_detection_model, wake_word_model
    
    try:
        # Load face detection model (YOLOv2 face detection)
        face_detection_model = kpu.load("/sd/face_detect.kmodel")
        print("[K210] Face detection model loaded")
        
        # Load wake word detection model (if available)
        # wake_word_model = kpu.load("/sd/wake_word.kmodel")
        # print("[K210] Wake word model loaded")
        
        return True
    except Exception as e:
        print(f"[K210] Error loading models: {e}")
        return False

def send_to_esp32(message_type, data):
    """Send structured message to ESP32"""
    try:
        message = {
            "type": message_type,
            "timestamp": utime.ticks_ms(),
            "data": data
        }
        json_msg = json.dumps(message) + "\n"
        uart.write(json_msg.encode())
        print(f"[K210→ESP32] {message_type}: {data}")
    except Exception as e:
        print(f"[K210] UART send error: {e}")

def receive_from_esp32():
    """Receive and parse commands from ESP32"""
    try:
        if uart.any():
            data = uart.read()
            if data:
                lines = data.decode().strip().split('\n')
                for line in lines:
                    if line:
                        try:
                            command = json.loads(line)
                            state.commands_queue.append(command)
                            print(f"[ESP32→K210] Command: {command}")
                        except:
                            print(f"[K210] Invalid JSON: {line}")
    except Exception as e:
        print(f"[K210] UART receive error: {e}")

def process_face_detection():
    """Real-time face detection and recognition"""
    global face_detection_model
    
    if not face_detection_model:
        return
    
    try:
        img = sensor.snapshot()
        
        # Run face detection
        fmap = kpu.forward(face_detection_model, img)
        plist = kpu.face_detect(fmap)
        
        current_time = utime.ticks_ms()
        face_found = len(plist) > 0
        
        # Draw bounding boxes and analyze faces
        faces_data = []
        for i, p in enumerate(plist):
            # Draw rectangle around face
            img.draw_rectangle(p.rect(), color=(0, 255, 0), thickness=2)
            
            # Extract face features
            face_info = {
                "id": i,
                "confidence": p.confidence(),
                "rect": {
                    "x": p.rect()[0],
                    "y": p.rect()[1], 
                    "w": p.rect()[2],
                    "h": p.rect()[3]
                }
            }
            faces_data.append(face_info)
        
        # Update state and send to ESP32
        if face_found != state.face_detected:
            state.face_detected = face_found
            state.last_face_time = current_time
            
            send_to_esp32("face_detection", {
                "detected": face_found,
                "count": len(plist),
                "faces": faces_data
            })
        
        # Display status on LCD
        img.draw_string(2, 2, f"Faces: {len(plist)}", color=(255, 255, 0), scale=2)
        img.draw_string(2, 20, f"Mode: {state.mode}", color=(255, 255, 0), scale=1)
        
        lcd.display(img)
        
    except Exception as e:
        print(f"[K210] Face detection error: {e}")

def process_audio():
    """Audio processing and wake word detection"""
    # TODO: Implement audio processing
    # This would handle:
    # - Wake word detection
    # - Voice command recognition  
    # - Audio feature extraction
    pass

def process_image_analysis(image_data=None):
    """Advanced image analysis beyond face detection"""
    try:
        img = image_data if image_data else sensor.snapshot()
        
        # Object detection, scene analysis, etc.
        analysis_result = {
            "brightness": img.get_stats().l_mean(),
            "has_motion": False,  # TODO: Implement motion detection
            "objects": [],        # TODO: Object detection
            "scene": "indoor"     # TODO: Scene classification
        }
        
        send_to_esp32("image_analysis", analysis_result)
        
    except Exception as e:
        print(f"[K210] Image analysis error: {e}")

def process_commands():
    """Process commands from ESP32"""
    while state.commands_queue:
        command = state.commands_queue.pop(0)
        
        cmd_type = command.get("type", "")
        
        if cmd_type == "set_mode":
            new_mode = command.get("data", {}).get("mode", "idle")
            state.mode = new_mode
            print(f"[K210] Mode changed to: {new_mode}")
            
        elif cmd_type == "capture_image":
            # Capture and analyze specific image
            process_image_analysis()
            
        elif cmd_type == "start_audio":
            state.audio_active = True
            print("[K210] Audio processing started")
            
        elif cmd_type == "stop_audio":
            state.audio_active = False
            print("[K210] Audio processing stopped")
            
        elif cmd_type == "system_status":
            # Send system status to ESP32
            status = {
                "mode": state.mode,
                "face_detected": state.face_detected,
                "audio_active": state.audio_active,
                "memory_free": gc.mem_free(),
                "uptime": utime.ticks_ms()
            }
            send_to_esp32("status_response", status)

def main_loop():
    """Main processing loop"""
    print("[K210] T-Bao AI Engine starting...")
    
    # Initialize AI models
    if not init_ai_models():
        print("[K210] Warning: Running without AI models")
    
    # Send startup message to ESP32
    send_to_esp32("startup", {"status": "ready", "capabilities": ["face_detection", "image_analysis"]})
    
    frame_count = 0
    last_gc = utime.ticks_ms()
    
    while True:
        try:
            # Receive commands from ESP32
            receive_from_esp32()
            
            # Process queued commands
            process_commands()
            
            # Main AI processing based on current mode
            if state.mode == "face_detection" or state.mode == "idle":
                process_face_detection()
            
            if state.mode == "audio_processing" and state.audio_active:
                process_audio()
            
            # Periodic garbage collection
            frame_count += 1
            if frame_count % 30 == 0:  # Every 30 frames
                current_time = utime.ticks_ms()
                if utime.ticks_diff(current_time, last_gc) > 5000:  # Every 5 seconds
                    gc.collect()
                    last_gc = current_time
            
            # Small delay to prevent overwhelming the system
            time.sleep_ms(10)
            
        except KeyboardInterrupt:
            print("[K210] Shutting down...")
            break
        except Exception as e:
            print(f"[K210] Main loop error: {e}")
            time.sleep_ms(100)

if __name__ == "__main__":
    main_loop()
