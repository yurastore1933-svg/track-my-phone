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
