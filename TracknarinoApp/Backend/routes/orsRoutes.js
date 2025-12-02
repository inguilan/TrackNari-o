const express = require('express');
const router = express.Router();
const { obtenerRutaORS } = require('../services/orsService');
const verificarToken = require('../middleware/authMiddleware');

// POST /api/ors/ruta - Endpoint autenticado
router.post('/ruta', verificarToken, async (req, res) => {
  try {
    const { origen, destino } = req.body;

    console.log('📍 POST /api/ors/ruta recibido');
    console.log('   - Origen:', origen);
    console.log('   - Destino:', destino);

    // origen y destino deben ser arrays: [longitud, latitud]
    if (!Array.isArray(origen) || origen.length !== 2) {
      console.log('❌ Origen inválido');
      return res.status(400).json({ error: 'origen debe ser un array [lng, lat]' });
    }

    if (!Array.isArray(destino) || destino.length !== 2) {
      console.log('❌ Destino inválido');
      return res.status(400).json({ error: 'destino debe ser un array [lng, lat]' });
    }

    console.log('✅ Parámetros válidos, calculando ruta...');
    const resultado = await obtenerRutaORS(origen, destino);

    if (resultado.error) {
      console.log('❌ Error al calcular ruta:', resultado.error);
      return res.status(500).json({ error: resultado.error });
    }

    console.log(`✅ Ruta calculada exitosamente: ${resultado.coordinates?.length || 0} puntos`);
    res.json(resultado);
  } catch (error) {
    console.error('❌ Error en /api/ors/ruta:', error);
    res.status(500).json({ error: error.message });
  }
});

module.exports = router;
