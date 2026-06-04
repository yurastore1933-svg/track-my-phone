#!/bin/bash

echo "========================================="
echo "  📱 Setup Track My Phone Project"
echo "========================================="

# Nama project
PROJECT="track-my-phone"

# Buat folder project
mkdir -p $PROJECT
cd $PROJECT

echo "📁 Membuat struktur folder..."
mkdir -p public routes

# ==================== package.json ====================
cat > package.json << 'EOF'
{
  "name": "track-my-phone",
  "version": "1.0.0",
  "description": "Aplikasi tracking lokasi ponsel real-time menggunakan GPS dan WebSocket",
  "main": "server.js",
  "scripts": {
    "start": "node server.js",
    "dev": "nodemon server.js"
  },
  "keywords": ["tracking", "gps", "phone", "location", "realtime"],
  "author": "",
  "license": "MIT",
  "dependencies": {
    "dotenv": "^16.4.5",
    "express": "^4.21.0",
    "socket.io": "^4.7.5"
  },
  "devDependencies": {
    "nodemon": "^3.1.4"
  }
}
EOF

# ==================== .gitignore ====================
cat > .gitignore << 'EOF'
node_modules/
.env
.DS_Store
*.log
EOF

# ==================== .env.example ====================
cat > .env.example << 'EOF'
PORT=3000
SESSION_SECRET=your-secret-key-here
EOF

# ==================== server.js ====================
cat > server.js << 'EOF'
require("dotenv").config();
const express = require("express");
const http = require("http");
const { Server } = require("socket.io");
const path = require("path");
const locationRoute = require("./routes/location");

const app = express();
const server = http.createServer(app);
const io = new Server(server);

const PORT = process.env.PORT || 3000;

app.use(express.json());
app.use(express.static(path.join(__dirname, "public")));

app.use("/api/location", locationRoute);

let deviceLocations = {};

io.on("connection", (socket) => {
  console.log(`📱 Device connected: ${socket.id}`);

  socket.on("update-location", (data) => {
    const { deviceId, latitude, longitude, accuracy, timestamp } = data;
    deviceLocations[deviceId] = {
      deviceId,
      latitude,
      longitude,
      accuracy,
      timestamp,
      lastSeen: new Date().toISOString(),
    };
    console.log(`📍 Location update from ${deviceId}: ${latitude}, ${longitude}`);
    io.emit("location-updated", deviceLocations[deviceId]);
  });

  socket.on("get-all-locations", () => {
    socket.emit("all-locations", Object.values(deviceLocations));
  });

  socket.on("disconnect", () => {
    console.log(`❌ Device disconnected: ${socket.id}`);
  });
});

app.get("/api/devices", (req, res) => {
  res.json(Object.values(deviceLocations));
});

server.listen(PORT, () => {
  console.log(`🚀 Server running at http://localhost:${PORT}`);
});
EOF

# ==================== routes/location.js ====================
cat > routes/location.js << 'EOF'
const express = require("express");
const router = express.Router();

router.post("/", (req, res) => {
  const { deviceId, latitude, longitude, accuracy } = req.body;
  if (!deviceId || !latitude || !longitude) {
    return res.status(400).json({ error: "deviceId, latitude, and longitude are required" });
  }
  res.json({
    success: true,
    message: "Location received",
    data: { deviceId, latitude, longitude, accuracy, timestamp: new Date().toISOString() },
  });
});

module.exports = router;
EOF

# ==================== public/index.html ====================
cat > public/index.html << 'EOF'
<!DOCTYPE html>
<html lang="id">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>Track My Phone - Dashboard</title>
  <link rel="stylesheet" href="style.css" />
  <link rel="stylesheet" href="https://unpkg.com/leaflet@1.9.4/dist/leaflet.css" />
</head>
<body>
  <div class="container">
    <aside class="sidebar">
      <h2>📱 Track My Phone</h2>
      <div class="device-list" id="deviceList">
        <p class="empty">Menunggu perangkat...</p>
      </div>
      <div class="status">
        <span id="connectionStatus">🔴 Disconnected</span>
      </div>
    </aside>
    <main class="map-container">
      <div id="map"></div>
    </main>
  </div>
  <script src="https://unpkg.com/leaflet@1.9.4/dist/leaflet.js"></script>
  <script src="/socket.io/socket.io.js"></script>
  <script src="script.js"></script>
</body>
</html>
EOF

# ==================== public/style.css ====================
cat > public/style.css << 'EOF'
* {
  margin: 0;
  padding: 0;
  box-sizing: border-box;
}

body {
  font-family: "Segoe UI", Tahoma, Geneva, Verdana, sans-serif;
  background: #1a1a2e;
  color: #eee;
}

.container {
  display: flex;
  height: 100vh;
}

.sidebar {
  width: 320px;
  background: #16213e;
  padding: 20px;
  display: flex;
  flex-direction: column;
  border-right: 2px solid #0f3460;
}

.sidebar h2 {
  font-size: 1.4rem;
  margin-bottom: 20px;
  color: #e94560;
}

.device-list {
  flex: 1;
  overflow-y: auto;
}

.device-card {
  background: #0f3460;
  border-radius: 8px;
  padding: 12px;
  margin-bottom: 10px;
  cursor: pointer;
  transition: transform 0.2s, box-shadow 0.2s;
  border-left: 4px solid #e94560;
}

.device-card:hover {
  transform: translateX(4px);
  box-shadow: 0 4px 12px rgba(233, 69, 96, 0.3);
}

.device-card h4 {
  color: #e94560;
  margin-bottom: 4px;
}

.device-card p {
  font-size: 0.8rem;
  color: #aaa;
}

.empty {
  color: #666;
  text-align: center;
  margin-top: 40px;
}

.status {
  margin-top: 16px;
  padding: 10px;
  background: #0f3460;
  border-radius: 6px;
  text-align: center;
  font-size: 0.85rem;
}

.map-container {
  flex: 1;
  position: relative;
}

#map {
  width: 100%;
  height: 100%;
}

@media (max-width: 768px) {
  .container {
    flex-direction: column;
  }
  .sidebar {
    width: 100%;
    max-height: 200px;
  }
}
EOF

# ==================== public/script.js ====================
cat > public/script.js << 'EOF'
const map = L.map("map").setView([-6.2088, 106.8456], 13);

L.tileLayer("https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png", {
  attribution: "&copy; OpenStreetMap contributors",
  maxZoom: 19,
}).addTo(map);

const socket = io();
const statusEl = document.getElementById("connectionStatus");
const deviceListEl = document.getElementById("deviceList");
const markers = {};

socket.on("connect", () => {
  statusEl.textContent = "🟢 Connected";
  statusEl.style.color = "#4caf50";
  socket.emit("get-all-locations");
});

socket.on("disconnect", () => {
  statusEl.textContent = "🔴 Disconnected";
  statusEl.style.color = "#f44336";
});

socket.on("location-updated", (device) => {
  updateDeviceMarker(device);
  updateDeviceList(device);
});

socket.on("all-locations", (devices) => {
  devices.forEach((device) => {
    updateDeviceMarker(device);
    updateDeviceList(device);
  });
});

function updateDeviceMarker(device) {
  const { deviceId, latitude, longitude, accuracy } = device;
  if (markers[deviceId]) {
    markers[deviceId].setLatLng([latitude, longitude]);
    markers[deviceId].getPopup().setContent(popupContent(device));
  } else {
    const marker = L.marker([latitude, longitude])
      .addTo(map)
      .bindPopup(popupContent(device));
    marker.on("click", () => map.setView([latitude, longitude], 16));
    markers[deviceId] = marker;
    if (accuracy) {
      L.circle([latitude, longitude], {
        radius: accuracy,
        color: "#e94560",
        fillColor: "#e94560",
        fillOpacity: 0.15,
      }).addTo(map);
    }
  }
}

function popupContent(device) {
  return `
    <strong>${device.deviceId}</strong><br>
    📍 ${device.latitude.toFixed(6)}, ${device.longitude.toFixed(6)}<br>
    🎯 Akurasi: ${device.accuracy ? device.accuracy + "m" : "N/A"}<br>
    🕐 ${new Date(device.timestamp).toLocaleString("id-ID")}
  `;
}

function updateDeviceList(device) {
  const existing = document.getElementById(`device-${device.deviceId}`);
  if (existing) {
    existing.querySelector("p").textContent =
      `${device.latitude.toFixed(4)}, ${device.longitude.toFixed(4)}`;
  } else {
    if (deviceListEl.querySelector(".empty")) {
      deviceListEl.innerHTML = "";
    }
    const card = document.createElement("div");
    card.className = "device-card";
    card.id = `device-${device.deviceId}`;
    card.innerHTML = `
      <h4>📱 ${device.deviceId}</h4>
      <p>📍 ${device.latitude.toFixed(4)}, ${device.longitude.toFixed(4)}</p>
      <p>🕐 ${new Date(device.lastSeen).toLocaleTimeString("id-ID")}</p>
    `;
    card.onclick = () => {
      map.setView([device.latitude, device.longitude], 16);
      if (markers[device.deviceId]) markers[device.deviceId].openPopup();
    };
    deviceListEl.appendChild(card);
  }
}
EOF

# ==================== README.md ====================
cat > README.md << 'EOF'
# 📱 Track My Phone

Aplikasi **real-time phone tracking** menggunakan GPS dan WebSocket.

## 🚀 Fitur

- 🔴 **Real-time tracking** via WebSocket (Socket.IO)
- 🗺️ **Peta interaktif** dengan Leaflet + OpenStreetMap
- 📱 **Multi-device support** — lacak banyak ponsel
- 🎯 **Akurasi GPS** ditampilkan di peta
- 🌐 **REST API** untuk integrasi mobile app
- 📱 **Responsive** — mobile & desktop

## 📦 Instalasi

```bash
npm install
cp .env.example .env
npm start
