const mongoose = require('mongoose');

const alertaSeguridadSchema = new mongoose.Schema({
  tipo: {
    type: String,
    enum: ['trancon', 'sospecha', 'intento_robo', 'robo', 'obstaculo', 'clima', 'accidente', 'policia', 'otro'],
    required: true
  },
  descripcion: {
    type: String
  },
  usuario: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  coords: {
    lat: { type: Number, required: true },
    lng: { type: Number, required: true }
  },
  compartir: {
    type: Boolean,
    default: true
  },
  imagenUrl: {
    type: String
  },
  timestamp: {
    type: Date,
    default: Date.now
  }
}, {
  timestamps: true
});

// Índice para búsquedas geoespaciales más rápidas
alertaSeguridadSchema.index({ 'coords.lat': 1, 'coords.lng': 1 });
alertaSeguridadSchema.index({ createdAt: -1 });

module.exports = mongoose.model('AlertaSeguridad', alertaSeguridadSchema);
