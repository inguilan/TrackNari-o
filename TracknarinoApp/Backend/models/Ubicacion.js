const mongoose = require('mongoose');

const ubicacionSchema = new mongoose.Schema({
  camionero: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  coords: {
    lat: { type: Number, required: true },
    lng: { type: Number, required: true }
  },
  timestamp: { type: Date, default: Date.now }
});

module.exports = mongoose.model('Ubicacion', ubicacionSchema);
