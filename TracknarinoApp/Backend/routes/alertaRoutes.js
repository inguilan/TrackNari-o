const express = require('express');
const router = express.Router();
const AlertaSeguridad = require('../models/AlertaSeguridad');
const verificarToken = require('../middleware/authMiddleware');

// Crear una alerta
const crearAlertaHandler = async (req, res) => {
  try {
    const { tipo, descripcion, coords, compartir, imagenUrl } = req.body;

    console.log('📝 Creando alerta:', { tipo, coords, usuario: req.usuario.id });

    if (!coords || !coords.lat || !coords.lng) {
      return res.status(400).json({ error: 'Coordenadas son obligatorias' });
    }

    const alerta = new AlertaSeguridad({
      tipo,
      descripcion,
      coords,
      usuario: req.usuario.id,
      compartir: compartir !== false, // por defecto true
      imagenUrl
    });

    await alerta.save();
    await alerta.populate('usuario', 'nombre tipoUsuario');

    console.log('✅ Alerta creada con ID:', alerta._id);

    res.status(201).json({ mensaje: 'Alerta registrada con éxito', alerta });
  } catch (error) {
    console.error('❌ Error al crear alerta:', error);
    res.status(500).json({ error: 'Error al registrar la alerta', detalles: error.message });
  }
};

// Rutas para crear alertas (ambas apuntan al mismo handler)
router.post('/crear', verificarToken, crearAlertaHandler);
router.post('/', verificarToken, crearAlertaHandler);

// Listar alertas recientes (máx 50) - SIN autenticación para que todos vean
router.get('/listar', async (req, res) => {
  try {
    console.log('📋 Listando alertas recientes...');
    
    const alertas = await AlertaSeguridad.find({ compartir: true })
      .sort({ createdAt: -1 })
      .limit(50)
      .populate('usuario', 'nombre tipoUsuario');
    
    console.log(`✅ Alertas encontradas: ${alertas.length}`);
    res.json(alertas);
  } catch (error) {
    console.error('❌ Error al listar alertas:', error);
    res.status(500).json({ error: 'Error al obtener las alertas' });
  }
});

// Listar alertas recientes (últimas 24 horas)
router.get('/recientes', async (req, res) => {
  try {
    console.log('📋 Buscando alertas de últimas 24h...');
    
    const hace24h = new Date(Date.now() - 24 * 60 * 60 * 1000);
    const alertas = await AlertaSeguridad.find({ 
      compartir: true,
      createdAt: { $gte: hace24h }
    })
      .sort({ createdAt: -1 })
      .populate('usuario', 'nombre tipoUsuario');
    
    console.log(`✅ Alertas de últimas 24h: ${alertas.length}`);
    res.json(alertas);
  } catch (error) {
    console.error('❌ Error al buscar alertas recientes:', error);
    res.status(500).json({ error: 'Error al obtener alertas recientes' });
  }
});

// Listar alertas cercanas a una ubicación (lat, lng, radio en metros)
// CAMBIO: Remover verificarToken para permitir acceso sin autenticación
router.post('/cercanas', async (req, res) => {
  try {
    const { lat, lng, radio } = req.body;

    console.log('🔍 Buscando alertas cercanas:', { lat, lng, radio });

    if (!lat || !lng) {
      return res.status(400).json({ error: 'Latitud y longitud son obligatorios' });
    }

    const centro = {
      lat: parseFloat(lat),
      lng: parseFloat(lng)
    };

    const rangoMetros = radio ? parseFloat(radio) : 50000; // 50km por defecto

    // Solo buscar alertas compartidas
    const todas = await AlertaSeguridad.find({ compartir: true })
      .sort({ createdAt: -1 })
      .limit(100)
      .populate('usuario', 'nombre tipoUsuario');

    console.log(`📊 Total de alertas compartidas en BD: ${todas.length}`);
    
    if (todas.length === 0) {
      console.log('⚠️ No hay alertas en la base de datos');
      return res.json([]);
    }

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

    console.log(`✅ Alertas cercanas encontradas: ${cercanas.length}`);

    res.json(cercanas);
  } catch (error) {
    console.error('Error al buscar alertas cercanas:', error);
    res.status(500).json({ error: 'Error al buscar alertas cercanas', detalles: error.message });
  }
});

module.exports = router;
