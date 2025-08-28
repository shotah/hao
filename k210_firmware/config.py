# T-Bao K210 Configuration
# =========================
# Configuration settings for T-Bao AI Engine

# Hardware Configuration
class HardwareConfig:
    # Camera settings
    CAMERA_WIDTH = 320
    CAMERA_HEIGHT = 240
    CAMERA_FPS = 15
    
    # LCD settings
    LCD_WIDTH = 240
    LCD_HEIGHT = 240
    LCD_ROTATION = 2
    
    # UART settings for ESP32 communication
    UART_BAUDRATE = 115200
    UART_TX_PIN = 4
    UART_RX_PIN = 5
    
    # Audio settings
    AUDIO_SAMPLE_RATE = 16000
    AUDIO_CHANNELS = 1

# AI Model Configuration
class ModelConfig:
    # Face detection
    FACE_DETECTION_MODEL = "/sd/face_detect.kmodel"
    FACE_CONFIDENCE_THRESHOLD = 0.7
    FACE_NMS_THRESHOLD = 0.4
    
    # Wake word detection
    WAKE_WORD_MODEL = "/sd/wake_word.kmodel"
    WAKE_WORD_THRESHOLD = 0.8
    
    # Object detection (optional)
    OBJECT_DETECTION_MODEL = "/sd/object_detect.kmodel"
    OBJECT_CONFIDENCE_THRESHOLD = 0.6

# Communication Protocol
class CommConfig:
    # Message types for ESP32 communication
    MESSAGE_TYPES = {
        'STARTUP': 'startup',
        'FACE_DETECTION': 'face_detection',
        'IMAGE_ANALYSIS': 'image_analysis',
        'AUDIO_EVENT': 'audio_event',
        'STATUS_RESPONSE': 'status_response',
        'ERROR': 'error'
    }
    
    # Command types from ESP32
    COMMAND_TYPES = {
        'SET_MODE': 'set_mode',
        'CAPTURE_IMAGE': 'capture_image',
        'START_AUDIO': 'start_audio',
        'STOP_AUDIO': 'stop_audio',
        'SYSTEM_STATUS': 'system_status'
    }

# Performance Configuration
class PerformanceConfig:
    # Memory management
    GC_INTERVAL = 30  # frames between garbage collection
    GC_THRESHOLD = 5000  # milliseconds between forced GC
    
    # Processing intervals
    FACE_DETECTION_INTERVAL = 50  # milliseconds
    STATUS_REPORT_INTERVAL = 30000  # milliseconds
    
    # Buffer sizes
    UART_BUFFER_SIZE = 4096
    MESSAGE_QUEUE_SIZE = 10

# System Configuration
class SystemConfig:
    # Operating modes
    MODES = {
        'IDLE': 'idle',
        'FACE_DETECTION': 'face_detection',
        'AUDIO_PROCESSING': 'audio_processing',
        'IMAGE_ANALYSIS': 'image_analysis',
        'SLEEP': 'sleep'
    }
    
    # Default mode
    DEFAULT_MODE = 'idle'
    
    # Debug settings
    DEBUG_ENABLED = True
    VERBOSE_LOGGING = False
    
    # Watchdog settings
    WATCHDOG_ENABLED = True
    WATCHDOG_TIMEOUT = 10000  # milliseconds

# Export configurations
hw_config = HardwareConfig()
model_config = ModelConfig()
comm_config = CommConfig()
perf_config = PerformanceConfig()
sys_config = SystemConfig()
