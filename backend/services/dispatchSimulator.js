const Incident = require('../models/Incident');

// In-memory store of active simulations
const activeSimulations = new Map();

/**
 * Starts a dispatch simulation for a given incident
 * @param {string} incidentId The ID of the incident
 * @param {object} io The Socket.io server instance
 */
const startDispatchSimulation = async (incidentId, io) => {
  if (activeSimulations.has(incidentId)) {
    return; // Simulation already running for this incident
  }

  try {
    const incident = await Incident.findById(incidentId);
    if (!incident || incident.status !== 'DISPATCHED') return;

    // Initial mock assignments
    incident.responseTeamId = `TEAM-${Math.floor(Math.random() * 900) + 100}`;
    incident.eta = Math.floor(Math.random() * 10) + 5; // Random ETA between 5 and 15 mins
    await incident.save();

    // Emit update
    io.emit('incidentUpdated', incident);
    console.log(`🚓 Dispatch started for incident ${incidentId}. Team: ${incident.responseTeamId}, ETA: ${incident.eta} mins`);

    // Run simulation loop every 5 seconds (simulating 1 minute passing)
    const intervalId = setInterval(async () => {
      try {
        const currentIncident = await Incident.findById(incidentId);
        
        // Stop simulation if it's no longer dispatched (e.g. resolved or on the way)
        if (!currentIncident || currentIncident.status === 'RESOLVED') {
          clearInterval(intervalId);
          activeSimulations.delete(incidentId);
          return;
        }

        // Decrease ETA
        if (currentIncident.eta > 0) {
          currentIncident.eta -= 1;
          
          if (currentIncident.eta === 0) {
            currentIncident.status = 'ON_THE_WAY'; // Change status when they arrive
          }
          
          await currentIncident.save();
          io.emit('incidentUpdated', currentIncident);
          console.log(`🚓 Update for incident ${incidentId}: ETA is now ${currentIncident.eta} mins`);
        } else {
          // Arrived
          clearInterval(intervalId);
          activeSimulations.delete(incidentId);
        }
      } catch (err) {
        console.error(`Error in dispatch simulation for ${incidentId}:`, err);
        clearInterval(intervalId);
        activeSimulations.delete(incidentId);
      }
    }, 5000); // 5 seconds in real life = 1 min in simulation

    activeSimulations.set(incidentId, intervalId);

  } catch (error) {
    console.error("Error starting dispatch simulation:", error);
  }
};

module.exports = {
  startDispatchSimulation
};
