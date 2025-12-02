const admin = require('firebase-admin');
const path = require('path');
const fs = require('fs');

const credPath = path.join(__dirname, '../config/firebase-key.json');
let fcmEnabled = false;

if (fs.existsSync(credPath)) {
  try {
    const serviceAccount = require(credPath);
    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount)
    });
    fcmEnabled = true;
    console.log('✅ Firebase Admin inicializado (FCM habilitado)');
  } catch (err) {
    console.error('⚠️ Error inicializando Firebase Admin:', err.message);
    fcmEnabled = false;
  }
} else {
  console.warn('⚠️ Archivo de credenciales de Firebase no encontrado. FCM deshabilitado en este entorno.');
}

async function enviarNotificacionFCM(deviceToken, titulo, cuerpo) {
  if (!fcmEnabled) {
    console.log('FCM deshabilitado — simulando envío de notificación:', { deviceToken, titulo, cuerpo });
    return null;
  }

  const mensaje = {
    notification: {
      title: titulo,
      body: cuerpo
    },
    token: deviceToken
  };

  try {
    const response = await admin.messaging().send(mensaje);
    console.log('✅ Notificación enviada:', response);
    return response;
  } catch (error) {
    console.error('❌ Error al enviar notificación:', error);
    throw error;
  }
}

module.exports = { enviarNotificacionFCM };
