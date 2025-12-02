const express = require('express');
const router = express.Router();
const User = require('../models/User');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const verificarToken = require('../middleware/authMiddleware');

// Handler de registro reutilizable (acepta '/registro' y '/register')
async function handleRegistro(req, res) {
  const { nombre, correo, contraseña, tipoUsuario, telefono, empresa, empresaAfiliada, licenciaExpedicion, numeroCedula, camion, metodoPago, disponibleParaSolicitarCamioneros } = req.body;

  console.log('\n🔵 INTENTO DE REGISTRO:');
  console.log('Datos recibidos:', { nombre, correo, tipoUsuario, empresa, telefono });

  // Validación de campos según tipo de usuario
  if (tipoUsuario === 'camionero' && (!camion || !numeroCedula || !licenciaExpedicion || !empresaAfiliada)) {
    console.log('❌ Faltan datos de camionero');
    return res.status(400).json({ error: 'Faltan datos de camionero' });
  }
  if (tipoUsuario === 'contratista' && (!empresa || disponibleParaSolicitarCamioneros === undefined)) {
    console.log('❌ Faltan datos de contratista');
    return res.status(400).json({ error: 'Faltan datos de contratista' });
  }

  try {
    // Validar que la contraseña no esté vacía
    if (!contraseña) {
      console.log('❌ Contraseña vacía');
      return res.status(400).json({ error: 'La contraseña es obligatoria' });
    }

    // Verificar si el usuario ya existe
    console.log('🔍 Buscando usuario con correo:', correo);
    const usuarioExistente = await User.findOne({ correo });
    if (usuarioExistente) {
      console.log('❌ El correo ya está registrado:', correo);
      console.log('Usuario existente:', { id: usuarioExistente._id, nombre: usuarioExistente.nombre, correo: usuarioExistente.correo });
      return res.status(400).json({ error: 'El correo ya está registrado' });
    }
    
    console.log('✅ Correo disponible, procediendo con el registro');

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
      metodoPago,
      disponibleParaSolicitarCamioneros
    });

    console.log('💾 Guardando nuevo usuario...');

    // Guardar el nuevo usuario
    await nuevoUsuario.save();
    console.log('✅ Usuario guardado exitosamente:', { id: nuevoUsuario._id, correo: nuevoUsuario.correo });

    // Generar el token JWT
    const token = jwt.sign({ id: nuevoUsuario._id, tipoUsuario }, process.env.JWT_SECRET, { expiresIn: '1h' });

    res.status(201).json({
      mensaje: 'Usuario registrado correctamente',
      token,
      usuario: nuevoUsuario
    });
  } catch (error) {
    // Log de error para diagnóstico
    console.log('❌ Error al registrar usuario:', error);
    console.log('❌ Stack trace:', error.stack);
    res.status(500).json({ error: 'Error al registrar usuario', details: error.message });
  }
}

// Registro de un nuevo usuario (rutas en español e inglés)
router.post('/registro', handleRegistro);
router.post('/register', handleRegistro);

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
