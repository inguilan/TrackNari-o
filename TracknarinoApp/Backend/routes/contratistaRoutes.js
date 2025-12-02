const express = require('express');
const router = express.Router();
const {
  afiliarCamionero,
  rechazarAfiliacion
} = require('../controllers/contratistaController');
const verificarToken = require('../middleware/authMiddleware');
const soloRol = require('../middleware/rolMiddleware');

// Afiliar camionero a contratista
router.post('/afiliar/:id', verificarToken, soloRol('contratista'), afiliarCamionero);

// Rechazar afiliación de camionero
router.post('/rechazar/:id', verificarToken, soloRol('contratista'), rechazarAfiliacion);

module.exports = router;
