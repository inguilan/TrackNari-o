const express = require('express');
const router = express.Router();
const Ubicacion = require('../models/Ubicacion');
const verificarToken = require('../middleware/authMiddleware');
const soloRol = require('../middleware/rolMiddleware');

// 📍 Camionero actualiza su ubicación
router.post('/actualizar', verificarToken, soloRol('camionero'), async (req, res) => {
  // Aceptar tanto lat/lng como latitud/longitud
  const lat = req.body.lat || req.body.latitud;
  const lng = req.body.lng || req.body.longitud;

  if (!lat || !lng) return res.status(400).json({ error: 'Latitud y longitud son obligatorios' });

  try {
    const ubicacion = new Ubicacion({
      camionero: req.usuario.id,
      coords: { lat, lng }
    });
    await ubicacion.save();
    res.json({ mensaje: 'Ubicación actualizada', ubicacion });
  } catch (error) {
    res.status(500).json({ error: 'Error al guardar ubicación' });
  }
});

// 🛰 Contratista consulta última ubicación de un camionero
router.get('/ultima/:idCamionero', verificarToken, soloRol('contratista'), async (req, res) => {
  try {
    const ultima = await Ubicacion.findOne({ camionero: req.params.idCamionero })
      .sort({ timestamp: -1 });

    if (!ultima) {
      return res.status(404).json({ error: 'No hay ubicación registrada para este camionero' });
    }

    res.json(ultima);
  } catch (error) {
    res.status(500).json({ error: 'Error al consultar ubicación' });
  }
});

module.exports = router;
