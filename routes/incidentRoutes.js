const express = require('express');
const router = express.Router();

let io;

// This function bridges the socket to your routes
const setIo = (ioInstance) => {
  io = ioInstance;
  console.log("🛠️ Socket.io successfully linked to Routes");
};

// Listen for the SOS event
router.get('/test', (req, res) => {
  res.json({ message: "Routes are working" });
});

// IMPORTANT: Export both the router and the setIo function
module.exports = { 
  router, 
  setIo 
};