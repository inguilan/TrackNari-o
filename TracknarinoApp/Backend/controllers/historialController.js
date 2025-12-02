const Oportunidad = require('../models/Oportunidad');

// Historial de cargas de un camionero
const historialCamionero = async (req, res) => {
  try {
    const cargas = await Oportunidad.find({
      camioneroAsignado: req.usuario.id
    }).populate('contratista', 'nombre correo');
    res.json(cargas);
  } catch (error) {
    res.status(500).json({ error: 'Error al obtener historial de cargas del camionero' });
  }
};

// Historial de asignaciones de un contratista
const historialContratista = async (req, res) => {
  try {
    const asignaciones = await Oportunidad.find({
      contratista: req.usuario.id
    }).populate('camioneroAsignado', 'nombre correo');
    res.json(asignaciones);
  } catch (error) {
    res.status(500).json({ error: 'Error al obtener historial del contratista' });
  }
};

module.exports = {
  historialCamionero,
  historialContratista
};
