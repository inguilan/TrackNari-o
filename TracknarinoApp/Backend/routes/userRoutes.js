const express = require('express');
const router = express.Router();
const User = require('../models/User');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const verificarToken = require('../middleware/authMiddleware');

// Registro de un nuevo usuario
router.post('/registro', async (req, res) => {
  const { nombre, correo, contraseña, tipoUsuario, telefono, empresa, empresaAfiliada, licenciaExpedicion, numeroCedula, camion, metodoPago, disponibleParaSolicitarCamioneros } = req.body;

  // Validación de campos según tipo de usuario
  if (tipoUsuario === 'camionero' && (!camion || !numeroCedula || !licenciaExpedicion || !empresaAfiliada)) {
    return res.status(400).json({ error: 'Faltan datos de camionero' });
  }
  if (tipoUsuario === 'contratista' && (!empresa || disponibleParaSolicitarCamioneros === undefined)) {
    return res.status(400).json({ error: 'Faltan datos de contratista' });
  }

  try {
    // Verificar si el usuario ya existe
    const usuarioExistente = await User.findOne({ correo });
    if (usuarioExistente) {
      return res.status(400).json({ error: 'El correo ya está registrado' });
    }

    // Encriptar la contraseña
    const hash = await bcrypt.hash(contraseña, 10);

    // Crear un nuevo usuario
    const nuevoUsuario = new User({
      nombre,
      correo,
      contraseña: hash,
      tipoUsuario,
      telefono,
      empresa,
      empresaAfiliada,
      licenciaExpedicion,
      numeroCedula,
      camion,
      metodoPago,  // Método de pago
      disponibleParaSolicitarCamioneros
    });

    // Guardar el nuevo usuario
    await nuevoUsuario.save();

    // Generar el token JWT
    const token = jwt.sign({ id: nuevoUsuario._id, tipoUsuario }, process.env.JWT_SECRET, { expiresIn: '1h' });

    res.status(201).json({
      mensaje: 'Usuario registrado correctamente',
      token,
      usuario: nuevoUsuario
    });
  } catch (error) {
    res.status(500).json({ error: 'Error al registrar usuario' });
  }
});

// Login de un usuario
router.post('/login', async (req, res) => {
  const { correo, contraseña } = req.body;

  try {
    const usuario = await User.findOne({ correo });
    if (!usuario) return res.status(400).json({ mensaje: 'Correo no registrado' });

    const coincide = await bcrypt.compare(contraseña, usuario.contraseña);
    if (!coincide) return res.status(401).json({ mensaje: 'Contraseña incorrecta' });

    const token = jwt.sign({ id: usuario._id, tipo: usuario.tipoUsuario }, process.env.JWT_SECRET, {
      expiresIn: '1d'
    });

    res.json({ token, usuario });
  } catch (error) {
    res.status(500).json({ error: 'Error al iniciar sesión' });
  }
});

// Obtener perfil del usuario autenticado
router.get('/perfil', verificarToken, async (req, res) => {
  try {
    const usuario = await User.findById(req.usuario.id).select('-contraseña');
    
    if (!usuario) {
      return res.status(404).json({ error: 'Usuario no encontrado' });
    }

    res.json(usuario);
  } catch (error) {
    console.error('Error al obtener perfil:', error);
    res.status(500).json({ error: 'Error al obtener perfil del usuario' });
  }
});

// Actualizar el método de pago del usuario
router.put('/actualizar-pago', verificarToken, async (req, res) => {
  const { metodoPago } = req.body;

  // Validar el método de pago
  if (!['Visa', 'Nequi', 'Efectivo'].includes(metodoPago)) {
    return res.status(400).json({ error: 'Método de pago inválido' });
  }

  try {
    const usuario = await User.findById(req.usuario.id);
    
    // Actualizar el campo 'metodoPago' en el usuario
    usuario.metodoPago = metodoPago;
    await usuario.save();

    res.json({ mensaje: 'Método de pago actualizado', usuario });
  } catch (error) {
    res.status(500).json({ error: 'Error al actualizar el método de pago' });
  }
});

module.exports = router;
