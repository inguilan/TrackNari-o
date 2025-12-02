const express = require('express');
const router = express.Router();
const AlertaSeguridad = require('../models/AlertaSeguridad');
const verificarToken = require('../middleware/authMiddleware');

// Crear una alerta
const crearAlertaHandler = async (req, res) => {
  try {
    const { tipo, descripcion, coords, compartir } = req.body;

    const alerta = new AlertaSeguridad({
      tipo,
      descripcion,
      coords,
      usuario: req.usuario.id,
      compartir: compartir !== false // por defecto true
    });

    await alerta.save();

    res.status(201).json({ mensaje: 'Alerta registrada con éxito', alerta });
  } catch (error) {
    console.error('Error al crear alerta:', error);
    res.status(500).json({ error: 'Error al registrar la alerta', detalles: error.message });
  }
};

// Rutas para crear alertas (ambas apuntan al mismo handler)
router.post('/crear', verificarToken, crearAlertaHandler);
router.post('/', verificarToken, crearAlertaHandler);

// Listar alertas recientes (máx 50)
router.get('/listar', async (req, res) => {
  try {
    const alertas = await AlertaSeguridad.find()
      .sort({ createdAt: -1 })
      .limit(50)
      .populate('usuario', 'nombre tipoUsuario');
    res.json(alertas);
  } catch (error) {
    res.status(500).json({ error: 'Error al obtener las alertas' });
  }
});

// Listar alertas cercanas a una ubicación (lat, lng, radio en metros)
router.post('/cercanas', async (req, res) => {
  try {
    const { lat, lng, radio } = req.body;

    if (!lat || !lng) {
      return res.status(400).json({ error: 'Latitud y longitud son obligatorios' });
    }

    const centro = {
      lat: parseFloat(lat),
      lng: parseFloat(lng)
    };

    const rangoMetros = radio ? parseFloat(radio) : 50000; // 50km por defecto

    const todas = await AlertaSeguridad.find()
      .sort({ createdAt: -1 })
      .limit(100)
      .populate('usuario', 'nombre tipoUsuario');

    // Función haversine para calcular distancia
    const haversine = (coords1, coords2) => {
      const R = 6371000; // Radio de la Tierra en metros
      const lat1Rad = coords1.lat * Math.PI / 180;
      const lat2Rad = coords2.lat * Math.PI / 180;
      const deltaLat = (coords2.lat - coords1.lat) * Math.PI / 180;
      const deltaLng = (coords2.lng - coords1.lng) * Math.PI / 180;

      const a = Math.sin(deltaLat / 2) * Math.sin(deltaLat / 2) +
                Math.cos(lat1Rad) * Math.cos(lat2Rad) *
                Math.sin(deltaLng / 2) * Math.sin(deltaLng / 2);
      
      const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
      return R * c;
    };

    const cercanas = todas.filter(alerta => {
      if (!alerta.coords || !alerta.coords.lat || !alerta.coords.lng) return false;

      const distancia = haversine(centro, {
        lat: alerta.coords.lat,
        lng: alerta.coords.lng
      });

      return distancia <= rangoMetros;
    });

    res.json(cercanas);
  } catch (error) {
    console.error('Error al buscar alertas cercanas:', error);
    res.status(500).json({ error: 'Error al buscar alertas cercanas', detalles: error.message });
  }
});

module.exports = router;
