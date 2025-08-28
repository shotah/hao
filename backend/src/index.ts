import 'dotenv/config';
import express from 'express';
import cors from 'cors';
import multer from 'multer';
import http from 'http';
import { WebSocketServer } from 'ws';
import { scheduleAll } from './util/scheduler.js';
import { Memory } from './memory/memory.js';
import { handleCompanionReply } from './services/aiService.js';

const app = express();
const server = http.createServer(app);
const wss = new WebSocketServer({ server, path: '/ws/subscribe' });
const upload = multer({ storage: multer.memoryStorage(), limits: { fileSize: 4 * 1024 * 1024 } });

const PORT = process.env.PORT ? Number(process.env.PORT) : 3000;
const allowedDeviceIds = (process.env.ALLOWED_DEVICE_IDS || '').split(',').map(s => s.trim()).filter(Boolean);

app.use(cors());
app.use(express.json({ limit: '2mb' }));
app.use('/public', express.static('public'));

// In-memory hub of WebSocket clients per device
const clients = new Map<string, Set<WebSocket>>();

// Health
app.get('/health', (_req, res) => res.json({ ok: true }));

// Basic text message from device
app.post('/api/message', async (req, res) => {
  const { deviceId, text } = req.body || {};
  if (!deviceId || !text) return res.status(400).json({ error: 'deviceId and text required' });
  if (allowedDeviceIds.length && !allowedDeviceIds.includes(deviceId)) return res.status(403).json({ error: 'device not allowed' });

  // Append to device memory
  Memory.append(deviceId, { type: 'user_text', text, ts: Date.now() });

  // Generate a friendly companion reply (placeholder AI)
  const reply = await handleCompanionReply(deviceId, text);

  // Optionally push reply to live WS clients
  broadcast(deviceId, { kind: 'reply', text: reply });

  res.json({ reply });
});

// Image analyze (photo bytes in multipart form: field "image")
app.post('/api/analyze', upload.single('image'), async (req, res) => {
  const { deviceId, prompt } = req.body || {};
  if (!deviceId || !req.file) return res.status(400).json({ error: 'deviceId and image required' });
  if (allowedDeviceIds.length && !allowedDeviceIds.includes(deviceId)) return res.status(403).json({ error: 'device not allowed' });

  // Store minimal event
  Memory.append(deviceId, { type: 'image', size: req.file.size, prompt: prompt || null, ts: Date.now() });

  // TODO: send to real vision model; for now, stub
  const reply = `I received an image of ${req.file.size} bytes${prompt ? ` with prompt: ${prompt}` : ''}.`;

  broadcast(deviceId, { kind: 'vision', text: reply });
  res.json({ reply });
});

// WebSocket subscription for proactive pushes
wss.on('connection', (ws, req) => {
  const url = new URL(req.url || '', `http://${req.headers.host}`);
  const deviceId = url.searchParams.get('deviceId') || 'unknown';

  if (allowedDeviceIds.length && !allowedDeviceIds.includes(deviceId)) {
    ws.close(1008, 'device not allowed');
    return;
  }

  if (!clients.has(deviceId)) clients.set(deviceId, new Set());
  clients.get(deviceId)!.add(ws);

  ws.send(JSON.stringify({ kind: 'hello', text: `Connected to companion server as ${deviceId}` }));

  ws.on('close', () => {
    clients.get(deviceId)?.delete(ws);
  });
});

function broadcast(deviceId: string, payload: any) {
  const set = clients.get(deviceId);
  if (!set) return;
  const msg = JSON.stringify(payload);
  for (const ws of set) {
    if (ws.readyState === ws.OPEN) ws.send(msg);
  }
}

// Expose broadcast to scheduler
export const Push = {
  toDevice(deviceId: string, payload: any) {
    broadcast(deviceId, payload);
  }
};

// Start server then schedule jobs
server.listen(PORT, () => {
  console.log(`[server] listening on :${PORT}`);
  scheduleAll(Push, Memory, allowedDeviceIds.length ? allowedDeviceIds : ['dev-001']);
});
