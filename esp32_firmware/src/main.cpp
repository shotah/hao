#include <Arduino.h>
#include <WiFi.h>
#include <HTTPClient.h>
#include <WebSocketsClient.h>
#include <ArduinoJson.h>
#include "secrets.h"

// Communication with K210
HardwareSerial K210Serial(1); // Use Serial1 for K210 communication

// WebSocket client for backend
WebSocketsClient webSocket;

// Timing
unsigned long lastPost = 0;
unsigned long lastK210Ping = 0;
unsigned long lastStatusCheck = 0;

// K210 Communication
struct K210Status {
  bool connected = false;
  String mode = "idle";
  bool face_detected = false;
  bool audio_active = false;
  unsigned long last_message = 0;
} k210_status;

// Message queues
String pendingK210Commands[10];
int k210CommandCount = 0;

// K210 Communication Functions
void sendToK210(const String& type, const String& data) {
  DynamicJsonDocument doc(1024);
  doc["type"] = type;
  doc["timestamp"] = millis();
  
  DynamicJsonDocument dataDoc(512);
  deserializeJson(dataDoc, data);
  doc["data"] = dataDoc;
  
  String message;
  serializeJson(doc, message);
  message += "\n";
  
  K210Serial.print(message);
  Serial.printf("[ESP32→K210] %s: %s\n", type.c_str(), data.c_str());
}

void setK210Mode(const String& mode) {
  sendToK210("set_mode", "{\"mode\":\"" + mode + "\"}");
}

void processK210Message(const String& message) {
  DynamicJsonDocument doc(1024);
  DeserializationError error = deserializeJson(doc, message);
  
  if (error) {
    Serial.printf("[K210] JSON parse error: %s\n", error.c_str());
    return;
  }
  
  String type = doc["type"];
  auto data = doc["data"];
  
  Serial.printf("[K210→ESP32] %s\n", type.c_str());
  
  if (type == "startup") {
    k210_status.connected = true;
    Serial.println("[K210] AI Engine connected and ready");
    setK210Mode("face_detection"); // Start with face detection
    
  } else if (type == "face_detection") {
    bool detected = data["detected"];
    int count = data["count"];
    
    k210_status.face_detected = detected;
    
    if (detected) {
      Serial.printf("[K210] Face detected! Count: %d\n", count);
      
      // Send face detection event to backend
      String payload = "{\"deviceId\":\"" + String(DEVICE_ID) + 
                      "\",\"text\":\"Face detected\",\"type\":\"face_event\",\"count\":" + 
                      String(count) + "}";
      postToBackend("/api/message", payload);
    }
    
  } else if (type == "image_analysis") {
    int brightness = data["brightness"];
    Serial.printf("[K210] Image analysis - Brightness: %d\n", brightness);
    
  } else if (type == "status_response") {
    k210_status.mode = data["mode"].as<String>();
    k210_status.face_detected = data["face_detected"];
    k210_status.audio_active = data["audio_active"];
    
    Serial.printf("[K210] Status - Mode: %s, Face: %s\n", 
                  k210_status.mode.c_str(), 
                  k210_status.face_detected ? "Yes" : "No");
  }
  
  k210_status.last_message = millis();
}

void handleK210Communication() {
  // Read messages from K210
  while (K210Serial.available()) {
    String message = K210Serial.readStringUntil('\n');
    message.trim();
    if (message.length() > 0) {
      processK210Message(message);
    }
  }
  
  // Check K210 connection health
  unsigned long now = millis();
  if (now - k210_status.last_message > 10000) { // 10 seconds timeout
    if (k210_status.connected) {
      Serial.println("[K210] Connection timeout - AI Engine may be disconnected");
      k210_status.connected = false;
    }
  }
  
  // Periodic status check
  if (now - lastStatusCheck > 30000) { // Every 30 seconds
    sendToK210("system_status", "{}");
    lastStatusCheck = now;
  }
}

void connectWifi() {
  WiFi.mode(WIFI_STA);
  WiFi.begin(WIFI_SSID, WIFI_PASS);
  Serial.print("Connecting to WiFi");
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
  Serial.println("\nWiFi connected: " + WiFi.localIP().toString());
}

void webSocketEvent(WStype_t type, uint8_t * payload, size_t length) {
  switch(type) {
    case WStype_DISCONNECTED:
      Serial.println("[WS] Disconnected");
      break;
    case WStype_CONNECTED:
      Serial.println("[WS] Connected");
      break;
    case WStype_TEXT:
      Serial.print("[WS] Message: ");
      Serial.write(payload, length);
      Serial.println();
      
      // Handle WebSocket commands
      String message = String((char*)payload);
      handleWebSocketMessage(message);
      break;
    default: break;
  }
}

void setupWS() {
  // ws://<host>:<port>/ws/subscribe?deviceId=<id>
  String path = String("/ws/subscribe?deviceId=") + DEVICE_ID;
  webSocket.begin(BACKEND_HOST, BACKEND_PORT, path.c_str());
  webSocket.onEvent(webSocketEvent);
  webSocket.setReconnectInterval(3000);
}

void postToBackend(const String& endpoint, const String& payload) {
  if (WiFi.status() == WL_CONNECTED) {
    HTTPClient http;
    String url = String("http://") + BACKEND_HOST + ":" + BACKEND_PORT + endpoint;
    http.begin(url);
    http.addHeader("Content-Type", "application/json");
    
    int code = http.POST(payload);
    Serial.printf("[HTTP] POST %s -> %d\n", endpoint.c_str(), code);
    
    if (code > 0) {
      String response = http.getString();
      Serial.printf("[HTTP] Response: %s\n", response.c_str());
    }
    
    http.end();
  }
}

void postHello() {
  String payload = "{\"deviceId\":\"" + String(DEVICE_ID) + "\",\"text\":\"Hello from T-Bao ESP32\",\"k210_status\":\"" + 
                   (k210_status.connected ? "connected" : "disconnected") + "\"}";
  postToBackend("/api/message", payload);
}

void handleWebSocketMessage(const String& message) {
  // Parse WebSocket message and potentially forward commands to K210
  DynamicJsonDocument doc(1024);
  DeserializationError error = deserializeJson(doc, message);
  
  if (!error) {
    String type = doc["type"];
    
    if (type == "set_ai_mode") {
      String mode = doc["mode"];
      setK210Mode(mode);
      Serial.printf("[WS] Setting AI mode to: %s\n", mode.c_str());
      
    } else if (type == "capture_image") {
      sendToK210("capture_image", "{}");
      Serial.println("[WS] Triggering image capture");
      
    } else if (type == "start_audio") {
      sendToK210("start_audio", "{}");
      Serial.println("[WS] Starting audio processing");
      
    } else if (type == "stop_audio") {
      sendToK210("stop_audio", "{}");
      Serial.println("[WS] Stopping audio processing");
    }
  }
}

void setup() {
  Serial.begin(115200);
  delay(100);
  
  // Initialize K210 communication (GPIO 16=RX, 17=TX for Serial1)
  K210Serial.begin(115200, SERIAL_8N1, 16, 17);
  Serial.println("[ESP32] K210 Serial initialized");
  
  connectWifi();
  setupWS();
  
  // Initial hello to backend
  delay(1000);
  postHello();
  
  Serial.println("[ESP32] T-Bao ESP32 Coordinator ready");
}

void loop() {
  // Handle WebSocket communication with backend
  webSocket.loop();
  
  // Handle K210 communication
  handleK210Communication();
  
  // Send periodic heartbeat to backend
  if (millis() - lastPost > 30000) { // Every 30 seconds
    lastPost = millis();
    postHello();
  }
  
  // Small delay to prevent overwhelming the system
  delay(10);
}
