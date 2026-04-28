const express = require("express");
const cors = require("cors");
const http = require("http");
const { Server } = require("socket.io");

// Make sure the path to your routes is exactly like this:
const { router: incidentRoutes, setIo } = require("./routes/incidentRoutes");

const app = express();
const server = http.createServer(app);

const io = new Server(server, {
  cors: {
    origin: "*",
    methods: ["GET", "POST"],
  },
});

// Link the socket to the routes
setIo(io);

app.use(cors());
app.use(express.json());

app.use("/incident", incidentRoutes);

app.get("/", (req, res) => {
  res.send("Havera Server is Live");
});

// Socket connection logic
io.on("connection", (socket) => {
  console.log("📡 A guest app connected! ID:", socket.id);
  
  socket.on("send_sos", (data) => {
    console.log("🚨 SOS RECEIVED:", data);
    io.emit("sos_received", { id: "HAV-" + Math.floor(Math.random()*1000) });
  });
});

const PORT = 3000;
server.listen(PORT, () => {
  console.log("========================================");
  console.log(`🚀 SERVER RUNNING ON PORT ${PORT}`);
  console.log("========================================");
});