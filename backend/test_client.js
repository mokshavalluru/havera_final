const io = require("socket.io-client");
const http = require("http");

const BASE_URL = "http://localhost:3000";

console.log("Connecting to socket server...");
const socket = io(BASE_URL);

socket.on("connect", () => {
  console.log("✅ Socket connected!");
  
  // 1. Create Incident
  console.log("Creating test incident...");
  const postData = JSON.stringify({
    roomNumber: "204",
    hotelName: "Test Hotel",
    description: "There is a medical emergency in the lobby, someone fainted.",
    location: "Lobby"
  });

  const req = http.request(`${BASE_URL}/incident/create`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Content-Length': Buffer.byteLength(postData)
    }
  }, (res) => {
    let data = '';
    res.on('data', (chunk) => { data += chunk; });
    res.on('end', () => {
      console.log("POST Response:", JSON.parse(data));
    });
  });
  req.write(postData);
  req.end();
});

// 2. Listen to AI updates
socket.on("incidentUpdated", (incident) => {
  console.log("\n--- INCIDENT UPDATE RECEIVED ---");
  console.log(`Status: ${incident.status}`);
  console.log(`Severity: ${incident.severity}`);
  console.log(`AI Summary: ${incident.aiSummary}`);
  console.log(`ETA: ${incident.eta}`);
  
  // 3. Dispatch after AI returns (simulating admin clicking dispatch)
  if (incident.status === "NEW" && incident.severity !== "PENDING") {
    console.log("\nAI finished. Simulating Admin Dispatch...");
    setTimeout(() => {
      const putData = JSON.stringify({
        id: incident.id,
        status: "DISPATCHED"
      });

      const putReq = http.request(`${BASE_URL}/incident/update-status`, {
        method: 'PUT',
        headers: {
          'Content-Type': 'application/json',
          'Content-Length': Buffer.byteLength(putData)
        }
      });
      putReq.write(putData);
      putReq.end();
    }, 2000);
  }

  // 4. Resolve when ETA reaches 0 or ON_THE_WAY
  if (incident.status === "ON_THE_WAY") {
    console.log("\nTeam arrived! Resolving incident...");
    setTimeout(() => {
      const putData = JSON.stringify({
        id: incident.id,
        status: "RESOLVED"
      });

      const putReq = http.request(`${BASE_URL}/incident/update-status`, {
        method: 'PUT',
        headers: {
          'Content-Type': 'application/json',
          'Content-Length': Buffer.byteLength(putData)
        }
      });
      putReq.write(putData);
      putReq.end();
    }, 1000);
  }

  if (incident.status === "RESOLVED") {
    console.log("✅ Simulation complete! Exiting...");
    process.exit(0);
  }
});
