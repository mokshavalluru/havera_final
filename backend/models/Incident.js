const mongoose = require('mongoose');

const incidentSchema = new mongoose.Schema({
  roomNumber: {
    type: String,
    required: true,
  },
  hotelName: {
    type: String,
    required: true,
  },
  description: {
    type: String,
    required: true,
  },
  location: {
    type: String,
    required: true,
  },
  status: {
    type: String,
    enum: ['NEW', 'DISPATCHED', 'ON_THE_WAY', 'RESOLVED'],
    default: 'NEW',
  },
  severity: {
    type: String,
    enum: ['LOW', 'MEDIUM', 'HIGH', 'PENDING'],
    default: 'PENDING',
  },
  aiSummary: {
    type: String,
    default: '',
  },
  recommendedActions: {
    type: [String],
    default: [],
  },
  responseTeamId: {
    type: String,
    default: null,
  },
  eta: {
    type: Number, // Estimated time of arrival in minutes
    default: null,
  }
}, { timestamps: true });

// Transform output to include 'id' instead of '_id' and '__v'
incidentSchema.set('toJSON', {
  transform: (document, returnedObject) => {
    returnedObject.id = returnedObject._id.toString();
    delete returnedObject._id;
    delete returnedObject.__v;
  }
});

module.exports = mongoose.model('Incident', incidentSchema);
