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
