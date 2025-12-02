const mongoose = require('mongoose');

const alertaSeguridadSchema = new mongoose.Schema({
  tipo: {
    type: String,
    enum: ['trancon', 'sospecha', 'intento_robo', 'robo', 'obstaculo'],
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
    lat: Number,
    lng: Number
  },
  timestamp: {
    type: Date,
    default: Date.now
  }
}, {
  timestamps: true
});

module.exports = mongoose.model('AlertaSeguridad', alertaSeguridadSchema);
