const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
require('dotenv').config();

// 📦 Rutas principales
const authRoutes = require('./routes/authRoutes');
const oportunidadRoutes = require('./routes/oportunidadRoutes');
const orsRoutes = require('./routes/orsRoutes');
const ubicacionRoutes = require('./routes/ubicacionRoutes');
const notificacionesRoutes = require('./routes/notificacionesRoutes');
const historialRoutes = require('./routes/historialRoutes');
const adminRoutes = require('./routes/adminRoutes');
const alertaRoutes = require('./routes/alertaRoutes'); 
const calificacionRoutes = require('./routes/calificacionRoutes'); // Rutas de calificaciones
const vehiculoRoutes = require('./routes/vehiculoRoutes');
const contratistaRoutes = require('./routes/contratistaRoutes');
const userRoutes = require('./routes/userRoutes');

// 🔐 Middleware personalizados
const verificarToken = require('./middleware/authMiddleware');
const { soloRol } = require('./middleware/rolMiddleware');

// 🚀 Servicios adicionales
const { obtenerRutaORS } = require('./services/orsService');
const { enviarNotificacionFCM } = require('./services/fcmService'); 

// Inicializar app
const app = express();

// 🛡️ Middlewares globales
// Configuración mejorada de CORS
app.use(cors({
  origin: function(origin, callback) {
    const allowedOrigins = [
      'http://localhost:3000',
      'http://localhost:4000',
      'http://localhost:8000',
      'http://localhost',
      'http://10.0.2.2:4000',
      'https://trackarino.com',
      // Dominios de Render
      'https://tracknarino-backend.onrender.com',
      // Dominios de Vercel
      'https://tracknarino.vercel.app'
    ];

    // Permitir solicitudes sin origen (como aplicaciones móviles o herramientas como curl)
    if (!origin) {
      return callback(null, true);
    }

    // Aceptar cualquier puerto en localhost o 127.0.0.1 para desarrollo
    const localhostRegex = /^https?:\/\/(localhost|127\.0\.0\.1)(:\d+)?$/;
    
    // En producción, permitir dominios de Vercel y Render
    const vercelRegex = /^https:\/\/.*\.vercel\.app$/;
    const renderRegex = /^https:\/\/.*\.onrender\.com$/;

    if (allowedOrigins.indexOf(origin) !== -1 || 
        localhostRegex.test(origin) || 
        vercelRegex.test(origin) ||
        renderRegex.test(origin)) {
      return callback(null, true);
    }

    // Bloquear y registrar el origen no permitido
    console.warn(`CORS bloqueó solicitud desde origen: ${origin}`);
    return callback(new Error('Origen no permitido por CORS'));
  },
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization', 'X-Requested-With']
}));

// Aumentar límite de peso de los JSON
app.use(express.json({ limit: '50mb' }));
app.use(express.urlencoded({ extended: true, limit: '50mb' }));

// Logger middleware para desarrollo
app.use((req, res, next) => {
  console.log(`${new Date().toISOString()} - ${req.method} ${req.url}`);
  next();
});

// 🔗 Montar rutas
app.use('/api/auth', authRoutes);
app.use('/api/oportunidades', oportunidadRoutes);
app.use('/api/ors', orsRoutes);
app.use('/api/ubicacion', ubicacionRoutes);
app.use('/api/notificaciones', notificacionesRoutes);
app.use('/api/historial', historialRoutes);
app.use('/api/admin', adminRoutes);
app.use('/api/alertas', alertaRoutes); 
app.use('/api/calificaciones', calificacionRoutes); // Rutas de calificaciones
app.use('/api/vehiculos', vehiculoRoutes);
app.use('/api/contratistas', contratistaRoutes);
app.use('/api/users', userRoutes);

// Ruta raíz de prueba
app.get('/', (req, res) => {
  res.send('Bienvenido al backend de Tracknariño');
});

// Middleware de manejo de errores
app.use((err, req, res, next) => {
  console.error(`Error: ${err.message}`);
  res.status(err.status || 500).json({
    mensaje: err.message || 'Error interno del servidor',
    error: process.env.NODE_ENV === 'development' ? err : {}
  });
});

// 🔌 Conexión a MongoDB
mongoose.connect(process.env.MONGO_URI || 'mongodb://localhost:27017/trackarino', {
  useNewUrlParser: true,
  useUnifiedTopology: true,
}).then(() => {
  console.log('🟢 Conectado a MongoDB');
}).catch((err) => {
  console.error('🔴 Error al conectar a MongoDB:', err);
});

// 🚀 Iniciar servidor
const PORT = process.env.PORT || 4000;
app.listen(PORT, () => {
  console.log(`🚀 Servidor corriendo en http://localhost:${PORT}`);
});
