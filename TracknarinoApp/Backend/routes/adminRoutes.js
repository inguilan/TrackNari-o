const express = require('express');
const router = express.Router();
const User = require('../models/User');
const verificarToken = require('../middleware/authMiddleware');
const soloRol = require('../middleware/rolMiddleware');

// Obtener todos los camioneros registrados
router.get('/camioneros', verificarToken, soloRol('contratista'), async (req, res) => {
  try {
    const camioneros = await User.find({ tipoUsuario: 'camionero' })
      .select('nombre correo telefono deviceToken createdAt');
    res.json(camioneros);
  } catch (error) {
    res.status(500).json({ error: 'Error al obtener la lista de camioneros' });
  }
});

// Obtener todos los contratistas registrados (opcional)
router.get('/contratistas', verificarToken, soloRol('contratista'), async (req, res) => {
  try {
    const contratistas = await User.find({ tipoUsuario: 'contratista' })
      .select('nombre correo telefono empresa createdAt');
    res.json(contratistas);
  } catch (error) {
    res.status(500).json({ error: 'Error al obtener la lista de contratistas' });
  }
});

module.exports = router;
