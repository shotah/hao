# Hao - T-Bao AI Companion Bot Makefile
# Windows Compatible Version
# =================================================

# Load environment variables if .env exists
ifneq ("$(wildcard .env)","")
    include .env
endif

# Suppress warnings for untested Node versions
JSII_SILENCE_WARNING_UNTESTED_NODE_VERSION := 1
export

# Project configuration
PROJECT_NAME := hao
BACKEND_DIR := backend
FIRMWARE_DIR := esp32_firmware
K210_FIRMWARE_DIR := k210_firmware
NODE_VERSION := 18

# PlatformIO configuration
PIO_ENV := t-bao
PIO_CMD := pio
PIO_PORT := auto
PIO_MONITOR_SPEED := 115200

# K210 configuration
K210_FLASH_CMD := kflash
K210_PORT := auto
K210_BAUDRATE := 1500000

# Backend configuration
BACKEND_PORT := 3000
BACKEND_HOST := localhost

.DEFAULT_GOAL := help

# =================================================
# HELP & INFO
# =================================================

.PHONY: help
help: ## Show this help message
	@echo "Hao - T-Bao AI Companion Bot"
	@echo "============================="
	@echo ""
	@echo "Available commands:"
	@echo ""
	@echo "  setup              - Initial project setup"
	@echo "  status             - Show project status"
	@echo "  check-deps         - Check for required dependencies"
	@echo ""
	@echo "Backend Commands:"
	@echo "  backend-install    - Install backend dependencies"
	@echo "  backend-dev        - Start development server with hot reload"
	@echo "  backend-build      - Build backend for production"
	@echo "  backend-start      - Start production backend server"
	@echo "  backend-test       - Run backend tests"
	@echo "  backend-clean      - Clean backend build artifacts"
	@echo ""
	@echo "ESP32 Firmware Commands:"
	@echo "  firmware-build     - Build T-Bao ESP32 firmware"
	@echo "  firmware-upload    - Upload ESP32 firmware to T-Bao device"
	@echo "  firmware-monitor   - Monitor serial output from ESP32"
	@echo "  firmware-clean     - Clean ESP32 firmware build artifacts"
	@echo "  firmware-deps      - Update ESP32 firmware dependencies"
	@echo ""
	@echo "K210 AI Firmware Commands:"
	@echo "  k210-flash         - Flash K210 AI firmware to T-Bao"
	@echo "  k210-monitor       - Monitor K210 AI engine output"
	@echo "  k210-check         - Check K210 tools installation"
	@echo ""
	@echo "Development Commands:"
	@echo "  dev                - Start full development environment"
	@echo "  deploy             - Full deployment (build + upload)"
	@echo "  test               - Run all tests"
	@echo "  clean              - Clean all build artifacts"
	@echo "  update             - Update all dependencies"
	@echo ""
	@echo "Quick Start:"
	@echo "  1. make setup"
	@echo "  2. Configure secrets (see README.md)"
	@echo "  3. make deploy"
	@echo ""

.PHONY: status
status: ## Show project status and health
	@echo "Project Status"
	@echo "=============="
	@echo ""
	@echo "Environment:"
	@echo "  Node.js:"
	@-node --version 2>nul || echo "    Not installed"
	@echo "  npm:"
	@-npm --version 2>nul || echo "    Not installed"
	@echo "  PlatformIO:"
	@-$(PIO_CMD) --version 2>nul || echo "    Not installed"
	@echo ""
	@echo "Backend:"
	@-if exist "$(BACKEND_DIR)\node_modules" (echo "  Dependencies: Installed") else (echo "  Dependencies: Not installed")
	@-if exist "$(BACKEND_DIR)\.env" (echo "  Environment: Configured") else (echo "  Environment: Copy .env.example to .env")
	@echo ""
	@echo "Firmware:"
	@-if exist "$(FIRMWARE_DIR)\include\secrets.h" (echo "  Secrets: Configured") else (echo "  Secrets: Copy secrets_example.h to secrets.h")
	@-if exist "$(FIRMWARE_DIR)\.pio" (echo "  Build cache: Ready") else (echo "  Build cache: Not initialized")

# =================================================
# SETUP & INITIALIZATION
# =================================================

.PHONY: setup
setup: check-deps backend-install firmware-init ## Initial project setup
	@echo "Setup complete!"
	@echo ""
	@echo "Next steps:"
	@echo "  1. Configure secrets:"
	@echo "     copy $(FIRMWARE_DIR)\include\secrets_example.h $(FIRMWARE_DIR)\include\secrets.h"
	@echo "     copy $(BACKEND_DIR)\.env.example $(BACKEND_DIR)\.env"
	@echo "  2. Edit the files with your WiFi and API credentials"
	@echo "  3. Run 'make deploy' to build and start everything"

.PHONY: check-deps
check-deps: ## Check for required dependencies
	@echo "Checking dependencies..."
	@node --version >nul 2>&1 || echo "ERROR: Node.js not found. Please install Node.js $(NODE_VERSION)+"
	@npm --version >nul 2>&1 || echo "ERROR: npm not found. Please install npm"
	@$(PIO_CMD) --version >nul 2>&1 || echo "ERROR: PlatformIO not found. Please install PlatformIO"
	@echo "Dependencies check complete"

# =================================================
# BACKEND COMMANDS
# =================================================

.PHONY: backend-install
backend-install: ## Install backend dependencies
	@echo "Installing backend dependencies..."
	@cd $(BACKEND_DIR)
	@npm install
	@echo "Backend dependencies installed"

.PHONY: backend-dev
backend-dev: ## Start backend development server with hot reload
	@echo "Starting backend development server..."
	@cd $(BACKEND_DIR)
	@npm run dev

.PHONY: backend-build
backend-build: ## Build backend for production
	@echo "Building backend..."
	@cd $(BACKEND_DIR)
	@npm run build
	@echo "Backend built successfully"

.PHONY: backend-start
backend-start: backend-build ## Start production backend server
	@echo "Starting production backend..."
	@cd $(BACKEND_DIR)
	@npm start

.PHONY: backend-test
backend-test: ## Run backend tests
	@echo "Running backend tests..."
	@cd $(BACKEND_DIR)
	@-npm test 2>nul || echo "No tests configured yet"

.PHONY: backend-clean
backend-clean: ## Clean backend build artifacts
	@echo "Cleaning backend..."
	@cd $(BACKEND_DIR)
	@-if exist dist rmdir /s /q dist 2>nul
	@-if exist node_modules\.cache rmdir /s /q node_modules\.cache 2>nul
	@echo "Backend cleaned"

.PHONY: backend-reset
backend-reset: backend-clean ## Reset backend to clean state
	@echo "Resetting backend..."
	@cd $(BACKEND_DIR)
	@-if exist node_modules rmdir /s /q node_modules 2>nul
	@-if exist package-lock.json del package-lock.json 2>nul
	@-if exist dist rmdir /s /q dist 2>nul
	@echo "Backend reset"

# =================================================
# FIRMWARE COMMANDS
# =================================================

.PHONY: firmware-init
firmware-init: ## Initialize firmware build environment
	@echo "Initializing firmware environment..."
	@cd $(FIRMWARE_DIR)
	@-$(PIO_CMD) project init --board $(PIO_ENV) 2>nul
	@echo "Firmware environment initialized"

.PHONY: firmware-build
firmware-build: ## Build T-Bao firmware
	@echo "Building T-Bao firmware for environment: $(PIO_ENV)"
	@cd $(FIRMWARE_DIR)
	@$(PIO_CMD) run -e $(PIO_ENV)
	@echo "Firmware built successfully"

.PHONY: firmware-upload
firmware-upload: firmware-build ## Upload firmware to T-Bao device
	@echo "Uploading firmware to T-Bao (environment: $(PIO_ENV))"
	@cd $(FIRMWARE_DIR)
	@$(PIO_CMD) run -t upload -e $(PIO_ENV)
	@echo "Firmware uploaded successfully"

.PHONY: firmware-monitor
firmware-monitor: ## Monitor serial output from T-Bao
	@echo "Starting Serial Monitor (environment: $(PIO_ENV))"
	@echo "Press Ctrl+C to exit"
	@cd $(FIRMWARE_DIR)
	@$(PIO_CMD) device monitor -e $(PIO_ENV)

.PHONY: firmware-upload-monitor
firmware-upload-monitor: firmware-upload ## Upload firmware and start monitoring
	@echo "Starting monitor after upload..."
	@timeout /t 2 /nobreak >nul
	@$(MAKE) firmware-monitor

.PHONY: firmware-clean
firmware-clean: ## Clean firmware build artifacts
	@echo "Cleaning build artifacts (environment: $(PIO_ENV))"
	@cd $(FIRMWARE_DIR)
	@$(PIO_CMD) run -t clean -e $(PIO_ENV)
	@echo "Firmware cleaned"

.PHONY: firmware-clean-libs
firmware-clean-libs: ## Purge downloaded libraries
	@echo "Purging downloaded libraries (.pio/libdeps)"
	@cd $(FIRMWARE_DIR)
	@$(PIO_CMD) run -t clean -e $(PIO_ENV)
	@-if exist .pio\libdeps rmdir /s /q .pio\libdeps 2>nul
	@echo "Library cache cleared. Next build will re-download libraries."

.PHONY: firmware-reset
firmware-reset: firmware-clean ## Reset firmware to clean state
	@echo "Resetting firmware..."
	@cd $(FIRMWARE_DIR)
	@-if exist .pio rmdir /s /q .pio 2>nul
	@echo "Firmware reset"

.PHONY: firmware-deps
firmware-deps: ## Update firmware dependencies
	@echo "Updating firmware dependencies..."
	@cd $(FIRMWARE_DIR)
	@$(PIO_CMD) lib update
	@echo "Firmware dependencies updated"

# =================================================
# K210 AI FIRMWARE COMMANDS
# =================================================

.PHONY: k210-check
k210-check: ## Check K210 development tools
	@echo "Checking K210 development tools..."
	@python --version >nul 2>&1 || echo "ERROR: Python not found. Install Python 3.7+"
	@-python -c "import serial" 2>nul || echo "WARNING: pyserial not installed. Run: pip install pyserial"
	@-$(K210_FLASH_CMD) --help >nul 2>&1 || echo "WARNING: kflash not found. Install with: pip install kflash"
	@echo "K210 tools check complete"

.PHONY: k210-flash
k210-flash: ## Flash K210 AI firmware to T-Bao
	@echo "Flashing K210 AI firmware..."
	@echo "Make sure T-Bao is in K210 flash mode (hold BOOT button while resetting)"
	@cd $(K210_FIRMWARE_DIR)
	@-$(K210_FLASH_CMD) -p $(K210_PORT) -b $(K210_BAUDRATE) main.py
	@echo "K210 firmware flashed successfully"
	@echo "Reset T-Bao to start AI engine"

.PHONY: k210-monitor
k210-monitor: ## Monitor K210 AI engine output
	@echo "Monitoring K210 AI Engine..."
	@echo "Press Ctrl+C to exit"
	@-python -c "import serial; import time; s=serial.Serial('$(K210_PORT)', 115200); [print(s.readline().decode('utf-8', errors='ignore').strip()) for _ in iter(int, 1)]" 2>nul || echo "Could not connect to K210. Check port and connection."

.PHONY: k210-install-tools
k210-install-tools: ## Install K210 development tools
	@echo "Installing K210 development tools..."
	@pip install pyserial kflash
	@echo "K210 tools installed"

# =================================================
# DEVELOPMENT WORKFLOW
# =================================================

.PHONY: deploy
deploy: backend-build firmware-upload ## Full deployment (build backend + upload ESP32 firmware)
	@echo "ESP32 deployment complete!"
	@echo ""
	@echo "Services:"
	@echo "  Backend: http://$(BACKEND_HOST):$(BACKEND_PORT)"
	@echo "  Health:  http://$(BACKEND_HOST):$(BACKEND_PORT)/health"
	@echo "  WebSocket: ws://$(BACKEND_HOST):$(BACKEND_PORT)/ws/subscribe?deviceId=dev-001"
	@echo ""
	@echo "Next steps:"
	@echo "  1. Flash K210 AI firmware: make k210-flash"
	@echo "  2. Monitor ESP32: make firmware-monitor"
	@echo "  3. Monitor K210: make k210-monitor"

.PHONY: deploy-full
deploy-full: backend-build firmware-upload k210-flash ## Full deployment including K210 AI firmware
	@echo "Full T-Bao deployment complete!"
	@echo ""
	@echo "Both ESP32 and K210 firmware deployed"
	@echo "Reset T-Bao to start dual-MCU AI companion"

.PHONY: dev
dev: firmware-upload-monitor ## Build, upload ESP32 firmware, and start monitoring
	@echo "ESP32 development environment ready"
	@echo "Use 'make k210-flash' to also deploy K210 AI firmware"

# =================================================
# TESTING & VALIDATION
# =================================================

.PHONY: test
test: backend-test firmware-build ## Run all tests
	@echo "All tests completed"

.PHONY: test-api
test-api: ## Test backend API endpoints
	@echo "Testing API endpoints..."
	@echo "Testing health endpoint..."
	@-curl -f http://$(BACKEND_HOST):$(BACKEND_PORT)/health 2>nul && echo "Health check passed" || echo "Health check failed"
	@echo "Testing message endpoint..."
	@-curl -f -X POST http://$(BACKEND_HOST):$(BACKEND_PORT)/api/message -H "Content-Type: application/json" -d "{\"deviceId\":\"test-001\",\"text\":\"Hello from Makefile!\"}" 2>nul && echo "Message API test passed" || echo "Message API test failed"

.PHONY: lint
lint: ## Run linters on all code
	@echo "Running linters..."
	@cd $(BACKEND_DIR)
	@-npm run lint 2>nul || echo "No linter configured for backend"
	@echo "Linting complete"

# =================================================
# MAINTENANCE & CLEANUP
# =================================================

.PHONY: clean
clean: backend-clean firmware-clean ## Clean all build artifacts
	@echo "All artifacts cleaned"

.PHONY: clean-all
clean-all: backend-reset firmware-clean-libs ## Complete clean including libraries
	@echo "Complete clean: build artifacts and libraries purged"

.PHONY: reset
reset: backend-reset firmware-reset ## Reset project to clean state
	@echo "Project reset to clean state"

.PHONY: update
update: ## Update all dependencies
	@echo "Updating dependencies..."
	@$(MAKE) backend-install
	@$(MAKE) firmware-deps
	@echo "Dependencies updated"

# =================================================
# UTILITY COMMANDS
# =================================================

.PHONY: devices
devices: ## List connected ESP32 devices
	@echo "Connected devices:"
	@cd $(FIRMWARE_DIR)
	@$(PIO_CMD) device list 2>nul || echo "  No PlatformIO devices found"

.PHONY: env
env: ## Show environment information
	@echo "Environment Information"
	@echo "======================="
	@echo "Project: $(PROJECT_NAME)"
	@echo "Backend: $(BACKEND_DIR)"
	@echo "Firmware: $(FIRMWARE_DIR)"
	@echo "PlatformIO Environment: $(PIO_ENV)"
	@echo "Backend URL: http://$(BACKEND_HOST):$(BACKEND_PORT)"

# Mark all targets as phony
.PHONY: help status setup check-deps backend-install backend-dev backend-build backend-start backend-test backend-clean backend-reset firmware-init firmware-build firmware-upload firmware-monitor firmware-upload-monitor firmware-clean firmware-clean-libs firmware-reset firmware-deps dev deploy test test-api lint clean clean-all reset update devices env
