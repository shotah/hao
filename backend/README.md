# Companion Bot Skeleton

This repo contains two pieces:

1. **backend/** — Express + TypeScript server that:
   - Handles `/api/message` (text) and `/api/analyze` (image)
   - Maintains per-device memory
   - Schedules proactive messages (morning routine, random check-ins)
   - Pushes messages to devices over WebSockets (`/ws/subscribe`)

2. **esp32_firmware/** — PlatformIO (ESP32 / Arduino) firmware that:
   - Connects to WiFi
   - Posts text to the backend
   - Subscribes to WebSocket updates for proactive messages
   - Prints to Serial now; later you can wire LCD, mic, camera

## Quickstart (Backend)

```bash
cd backend
cp .env.example .env
npm install
npm run dev
# server on http://localhost:3000
```

### Test endpoints

```bash
curl -X POST http://localhost:3000/api/message -H 'Content-Type: application/json' -d '{"deviceId":"dev-001","text":"Hello"}'
curl http://localhost:3000/health
```

### WebSocket test (in browser console)

```js
const ws = new WebSocket('ws://localhost:3000/ws/subscribe?deviceId=dev-001');
ws.onmessage = (e) => console.log('WS message:', e.data);
```

## Quickstart (ESP32)

1. Open `esp32_firmware` in PlatformIO.
2. Copy `include/secrets_example.h` → `include/secrets.h` and fill WiFi + backend host.
3. Build & upload to an ESP32 dev board (display logs over Serial 115200).

## Next steps

- Wire actual LCD + camera code on the ESP32.
- Replace the placeholder AI with real integrations in `src/services/aiService.ts`.
- Persist memory to a file or Redis instead of in-memory if needed.
