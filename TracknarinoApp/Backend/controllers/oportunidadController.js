const Oportunidad = require('../models/Oportunidad');
const User = require('../models/User');
const { enviarNotificacionFCM } = require('../services/fcmService');

// Crear oportunidad (contratista o camionero)
const crearOportunidad = async (req, res) => {
  try {
    console.log('\n🔵 CREAR OPORTUNIDAD:');
    console.log('Datos recibidos:', req.body);
    console.log('Usuario:', { id: req.usuario.id, tipo: req.usuario.tipoUsuario });

    // Validar campos obligatorios
    const { titulo, origen, destino, fecha, precio } = req.body;
    if (!titulo || !origen || !destino || !fecha || !precio) {
      console.log('❌ Faltan campos obligatorios');
      return res.status(400).json({ 
        error: 'Faltan campos obligatorios',
        requeridos: ['titulo', 'origen', 'destino', 'fecha', 'precio']
      });
    }

    // Si algunos campos no están presentes, establecer valores predeterminados
    const datosOportunidad = {
      ...req.body,
      contratista: req.usuario.id,
      estado: 'disponible',
      finalizada: false
    };

    console.log('Datos procesados para la oportunidad:', datosOportunidad);
    
    const oportunidad = new Oportunidad(datosOportunidad);
    await oportunidad.save();
    
    console.log('Oportunidad creada con éxito:', oportunidad);
    
    // Opcionalmente, enviar notificaciones a camioneros disponibles
    try {
      // Buscar camioneros disponibles (solo si quien crea es contratista)
      if (req.usuario.tipoUsuario === 'contratista') {
        const camioneros = await User.find({ 
          tipoUsuario: 'camionero', 
          deviceToken: { $exists: true, $ne: '' },
          disponible: true 
        });

        console.log(`Enviando notificaciones a ${camioneros.length} camioneros disponibles`);
        
        // Enviar notificación a cada camionero
        for (const camionero of camioneros) {
          if (camionero.deviceToken) {
            await enviarNotificacionFCM(
              camionero.deviceToken, 
              'Nueva oportunidad disponible', 
              `${req.usuario.nombre} ha publicado una nueva carga de ${oportunidad.origen} a ${oportunidad.destino}`
            );
          }
        }
      }
    } catch (notifError) {
      console.error('Error al enviar notificaciones:', notifError);
      // Continuamos aunque falle el envío de notificaciones
    }
    
    console.log('✅ Oportunidad creada exitosamente');
    res.status(201).json({ 
      mensaje: 'Oportunidad creada', 
      oportunidad,
      success: true
    });
  } catch (error) {
    console.error('Error al crear oportunidad:', error);
    res.status(500).json({ 
      mensaje: 'Error al crear oportunidad', 
      error: error.message,
      detalles: error.toString() 
    });
  }
};

// Listar oportunidades disponibles (pueden verlas todos los autenticados)
const listarOportunidades = async (req, res) => {
  try {
    console.log('\n📋 LISTAR OPORTUNIDADES');
    const oportunidades = await Oportunidad.find({ estado: 'disponible' })
      .populate('contratista', 'nombre correo');
    console.log(`✅ Encontradas ${oportunidades.length} oportunidades`);
    res.json(oportunidades);
  } catch (error) {
    res.status(500).json({ error: 'Error al listar oportunidades' });
  }
};

// Asignar camionero a oportunidad (cualquier camionero puede aceptar)
const asignarCamionero = async (req, res) => {
  try {
    const { id } = req.params;
    const camioneroId = req.usuario.id; // Obtener el ID del camionero desde el token de autenticación

    const oportunidad = await Oportunidad.findById(id);

    if (!oportunidad || oportunidad.estado !== 'disponible') {
      return res.status(400).json({ error: 'Oportunidad no disponible para asignación' });
    }

    oportunidad.camioneroAsignado = camioneroId;
    oportunidad.estado = 'asignada';
    await oportunidad.save();

    // Enviar notificación al camionero si tiene token FCM
    const camionero = await User.findById(camioneroId);
    if (camionero?.deviceToken) {
      await enviarNotificacionFCM(
        camionero.deviceToken,
        '📦 Nueva carga aceptada',
        `Has aceptado una carga de ${oportunidad.origen} a ${oportunidad.destino}.`
      );
    }

    res.json({ mensaje: 'Carga aceptada', oportunidad });
  } catch (error) {
    res.status(500).json({ error: 'Error al aceptar la carga' });
  }
};

// Finalizar carga (solo contratista)
const finalizarCarga = async (req, res) => {
  try {
    const carga = await Oportunidad.findById(req.params.id);

    if (!carga || carga.contratista.toString() !== req.usuario.id) {
      return res.status(403).json({ error: 'No tienes permisos para finalizar esta carga' });
    }

    carga.estado = 'finalizada';
    carga.finalizada = true;
    await carga.save();

    // Notificación al camionero
    const camionero = await User.findById(carga.camioneroAsignado);
    if (camionero?.deviceToken) {
      await enviarNotificacionFCM(
        camionero.deviceToken,
        '✔️ Carga finalizada',
        `La carga de ${carga.origen} a ${carga.destino} ha sido finalizada.`
      );
    }

    res.json({ mensaje: 'Carga finalizada correctamente', carga });
  } catch (error) {
    res.status(500).json({ error: 'Error al finalizar la carga' });
  }
};

// Aceptar oportunidad (verifica estado del camionero)
const aceptarOportunidad = async (req, res) => {
  try {
    const { id } = req.params;
    const camioneroId = req.usuario.id;

    // Verificar que el camionero no tenga viajes activos
    const viajeActivo = await Oportunidad.findOne({
      camioneroAsignado: camioneroId,
      estado: { $in: ['asignada', 'en_ruta'] }
    });

    if (viajeActivo) {
      return res.status(400).json({ 
        error: 'Ya tienes un viaje activo. Finaliza tu viaje actual antes de aceptar otra carga.',
        viajeActivo 
      });
    }

    const oportunidad = await Oportunidad.findById(id);

    if (!oportunidad) {
      return res.status(404).json({ error: 'Oportunidad no encontrada' });
    }

    if (oportunidad.estado !== 'disponible') {
      return res.status(400).json({ error: 'Esta oportunidad ya fue aceptada por otro camionero' });
    }

    // Actualizar estado de la oportunidad
    oportunidad.camioneroAsignado = camioneroId;
    oportunidad.estado = 'asignada';
    await oportunidad.save();

    // Poblar datos del camionero y contratista
    await oportunidad.populate('camioneroAsignado', 'nombre correo telefono');
    await oportunidad.populate('contratista', 'nombre correo');

    // Notificación al contratista
    const contratista = await User.findById(oportunidad.contratista);
    if (contratista?.deviceToken) {
      const camionero = await User.findById(camioneroId);
      await enviarNotificacionFCM(
        contratista.deviceToken,
        '✅ Carga aceptada',
        `${camionero.nombre} ha aceptado tu carga de ${oportunidad.origen} a ${oportunidad.destino}.`
      );
    }

    res.json({ mensaje: 'Carga aceptada exitosamente', oportunidad });
  } catch (error) {
    console.error('Error al aceptar oportunidad:', error);
    res.status(500).json({ error: 'Error al aceptar la carga' });
  }
};

// Obtener viaje activo del camionero
const obtenerViajeActivo = async (req, res) => {
  try {
    const camioneroId = req.usuario.id;

    const viajeActivo = await Oportunidad.findOne({
      camioneroAsignado: camioneroId,
      estado: { $in: ['asignada', 'en_ruta'] }
    })
    .populate('contratista', 'nombre correo telefono')
    .populate('camioneroAsignado', 'nombre correo');

    if (!viajeActivo) {
      return res.json({ viajeActivo: null });
    }

    res.json({ viajeActivo });
  } catch (error) {
    console.error('Error al obtener viaje activo:', error);
    res.status(500).json({ error: 'Error al obtener viaje activo' });
  }
};

// Iniciar viaje (cambiar estado a en_ruta)
const iniciarViaje = async (req, res) => {
  try {
    const { id } = req.params;
    const camioneroId = req.usuario.id;

    const oportunidad = await Oportunidad.findById(id);

    if (!oportunidad) {
      return res.status(404).json({ error: 'Oportunidad no encontrada' });
    }

    if (oportunidad.camioneroAsignado.toString() !== camioneroId) {
      return res.status(403).json({ error: 'No tienes permisos para iniciar este viaje' });
    }

    // Permitir iniciar si está asignada o ya en ruta (por si se refresca la app)
    if (oportunidad.estado !== 'asignada' && oportunidad.estado !== 'en_ruta') {
      return res.status(400).json({ error: 'Este viaje no está en estado válido para iniciar' });
    }

    // Si ya está en ruta, simplemente confirmar sin cambiar nada
    if (oportunidad.estado !== 'en_ruta') {
      oportunidad.estado = 'en_ruta';
      await oportunidad.save();
    }

    res.json({ mensaje: 'Viaje iniciado', oportunidad });
  } catch (error) {
    console.error('Error al iniciar viaje:', error);
    res.status(500).json({ error: 'Error al iniciar viaje' });
  }
};

// Cancelar viaje (camionero se sale del viaje)
const cancelarViaje = async (req, res) => {
  try {
    const { id } = req.params;
    const camioneroId = req.usuario.id;

    const oportunidad = await Oportunidad.findById(id);

    if (!oportunidad) {
      return res.status(404).json({ error: 'Oportunidad no encontrada' });
    }

    if (oportunidad.camioneroAsignado.toString() !== camioneroId) {
      return res.status(403).json({ error: 'No tienes permisos para cancelar este viaje' });
    }

    if (oportunidad.estado !== 'asignada' && oportunidad.estado !== 'en_ruta') {
      return res.status(400).json({ error: 'Este viaje no puede ser cancelado' });
    }

    // Volver a dejar la oportunidad disponible
    oportunidad.camioneroAsignado = null;
    oportunidad.estado = 'disponible';
    await oportunidad.save();

    // Notificar al contratista
    const contratista = await User.findById(oportunidad.contratista);
    if (contratista?.deviceToken) {
      const camionero = await User.findById(camioneroId);
      await enviarNotificacionFCM(
        contratista.deviceToken,
        '⚠️ Viaje cancelado',
        `${camionero.nombre} ha cancelado el viaje de ${oportunidad.origen} a ${oportunidad.destino}. La carga está disponible nuevamente.`
      );
    }

    res.json({ mensaje: 'Viaje cancelado', oportunidad });
  } catch (error) {
    console.error('Error al cancelar viaje:', error);
    res.status(500).json({ error: 'Error al cancelar viaje' });
  }
};

// Finalizar viaje (cambiar estado a finalizada)
const finalizarViaje = async (req, res) => {
  try {
    const { id } = req.params;
    const camioneroId = req.usuario.id;

    const oportunidad = await Oportunidad.findById(id);

    if (!oportunidad) {
      return res.status(404).json({ error: 'Oportunidad no encontrada' });
    }

    if (oportunidad.camioneroAsignado.toString() !== camioneroId) {
      return res.status(403).json({ error: 'No tienes permisos para finalizar este viaje' });
    }

    if (oportunidad.estado !== 'en_ruta') {
      return res.status(400).json({ error: 'Este viaje no está en ruta' });
    }

    // Cambiar estado a finalizada
    oportunidad.estado = 'finalizada';
    oportunidad.finalizada = true;
    await oportunidad.save();

    // Notificar al contratista
    const contratista = await User.findById(oportunidad.contratista);
    if (contratista?.deviceToken) {
      const camionero = await User.findById(camioneroId);
      await enviarNotificacionFCM(
        contratista.deviceToken,
        '✅ Viaje finalizado',
        `${camionero.nombre} ha completado el viaje de ${oportunidad.origen} a ${oportunidad.destino}.`
      );
    }

    res.json({ mensaje: 'Viaje finalizado exitosamente', oportunidad });
  } catch (error) {
    console.error('Error al finalizar viaje:', error);
    res.status(500).json({ error: 'Error al finalizar viaje' });
  }
};

module.exports = {
  crearOportunidad,
  listarOportunidades,
  asignarCamionero,
  finalizarCarga,
  aceptarOportunidad,
  obtenerViajeActivo,
  iniciarViaje,
  cancelarViaje,
  finalizarViaje
};
