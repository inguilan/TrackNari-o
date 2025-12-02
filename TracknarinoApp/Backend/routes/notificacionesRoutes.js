const express = require('express');
const router = express.Router();
const User = require('../models/User');
const verificarToken = require('../middleware/authMiddleware');

// Guardar o actualizar el deviceToken del usuario
router.post('/registrar-token', verificarToken, async (req, res) => {
  const { token } = req.body;

  if (!token) return res.status(400).json({ error: 'Token de dispositivo requerido' });

  try {
    const usuario = await User.findByIdAndUpdate(req.usuario.id, {
      deviceToken: token
    }, { new: true });

    res.json({ mensaje: 'Token actualizado correctamente', usuario });
  } catch (error) {
    res.status(500).json({ error: 'Error al guardar token' });
  }
});

module.exports = router;
