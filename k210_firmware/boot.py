# T-Bao K210 Boot Configuration
# =============================
# This file runs automatically when K210 starts up

import gc
import sys
from fpioa_manager import fm

print("[K210] T-Bao AI Engine initializing...")
print("[K210] MaixPy version:", sys.version)
print("[K210] Free memory:", gc.mem_free())

# Configure pins for T-Bao specific hardware
# UART1 for ESP32 communication (pins 4, 5)
fm.register(4, fm.fpioa.UART1_TX)
fm.register(5, fm.fpioa.UART1_RX)

# Camera pins (OV2640)
# Note: These may need adjustment based on actual T-Bao pinout
fm.register(11, fm.fpioa.SCCB_SCLK)
fm.register(13, fm.fpioa.SCCB_SDA)
fm.register(21, fm.fpioa.CMOS_RST)
fm.register(44, fm.fpioa.CMOS_PWDN)
fm.register(46, fm.fpioa.CMOS_XCLK)
fm.register(47, fm.fpioa.CMOS_VSYNC)
fm.register(48, fm.fpioa.CMOS_HREF)
fm.register(42, fm.fpioa.CMOS_PCLK)

# LCD pins (ST7789)
# Note: These may need adjustment based on actual T-Bao pinout
fm.register(36, fm.fpioa.SPI0_SS3)
fm.register(39, fm.fpioa.SPI0_SCLK)
fm.register(38, fm.fpioa.GPIOHS0)  # DC
fm.register(37, fm.fpioa.GPIOHS1)  # RST

print("[K210] Hardware pins configured for T-Bao")
print("[K210] Starting main application...")

# Run the main application
exec(open('main.py').read())
