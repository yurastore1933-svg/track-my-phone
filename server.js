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
