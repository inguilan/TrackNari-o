const mongoose = require('mongoose');

const oportunidadSchema = new mongoose.Schema({
  titulo: { type: String, required: true },
  descripcion: { type: String },
  origen: { type: String, required: true },
  destino: { type: String, required: true },
  direccionCargue: { type: String },
  direccionDescargue: { type: String },
  fecha: { type: Date, required: true },
  precio: { type: Number, required: true },
  pesoCarga: { type: Number }, // Peso en toneladas
  tipoCarga: { type: String }, // Tipo de carga (ej: productos agrícolas)
  requisitosEspeciales: { type: String }, // Requisitos especiales
  distanciaKm: { type: Number }, // Distancia calculada en km
  duracionEstimadaHoras: { type: Number }, // Duración estimada en horas
  estado: {
    type: String,
    enum: ['disponible', 'asignada', 'en_ruta', 'finalizada'],
    default: 'disponible'
  },
  finalizada: {
    type: Boolean,
    default: false
  },
  contratista: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  camioneroAsignado: { type: mongoose.Schema.Types.ObjectId, ref: 'User' }
}, {
  timestamps: true
});

module.exports = mongoose.model('Oportunidad', oportunidadSchema);
