const jwt = require('jsonwebtoken');

function verificarToken(req, res, next) {
  console.log('Verificando token de autenticación');
  console.log('Headers de autorización:', req.headers.authorization);

  // Extracting the token from the Authorization header
  const token = req.headers.authorization?.split(' ')[1];

  if (!token) {
    console.log('Error: Token no proporcionado');
    return res.status(401).json({ mensaje: 'Token no proporcionado' });
  }

  try {
    // Add more info for debugging
    console.log('Intentando verificar el token');
    const decoded = jwt.verify(token, process.env.JWT_SECRET || 'secret_dev_key');
    console.log('Token verificado correctamente:', decoded);
    req.usuario = decoded;
    next();
  } catch (error) {
    console.error('Error en verificación del token:', error.message);
    res.status(403).json({ mensaje: 'Token inválido o expirado', error: error.message });
  }
}

module.exports = verificarToken;
