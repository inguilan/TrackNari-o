# 🚀 Guía de Despliegue en Render

## 📋 Requisitos Previos
- Código subido a GitHub
- Cuenta en [Render.com](https://render.com) (gratis)
- MongoDB Atlas configurado

## 🔧 Paso 1: Configuración de Render

### 1.1 Crear Cuenta y Nuevo Web Service
1. Ve a https://render.com y regístrate con GitHub
2. Click en "New +" → "Web Service"
3. Conecta tu repositorio `TrackNari-o`
4. Render detectará automáticamente que es Node.js

### 1.2 Configuración del Servicio
- **Name**: `tracknarino-backend`
- **Region**: Oregon (US West) - más cercano a Latinoamérica
- **Branch**: `main`
- **Root Directory**: `Backend`
- **Runtime**: Node
- **Build Command**: `npm install`
- **Start Command**: `npm start`
- **Plan**: Free

## 🔐 Paso 2: Variables de Entorno

En la sección "Environment Variables", añade:

```
NODE_ENV=production
PORT=10000
MONGO_URI=mongodb+srv://guzdavid1108_db_user:eJBxFAjocy4LS2Gn@cluster0.z4lk362.mongodb.net/trackarino?retryWrites=true&w=majority&appName=Cluster0
JWT_SECRET=tracknarino_secret_key_2025_production_render
```

⚠️ **IMPORTANTE**: Usa un JWT_SECRET diferente para producción (más seguro)

## 🌐 Paso 3: MongoDB Atlas

### Configurar IP Whitelist
1. Ve a MongoDB Atlas → Network Access
2. Click "Add IP Address"
3. Selecciona "Allow Access from Anywhere" (0.0.0.0/0)
4. O añade las IPs de Render: consulta en Render Dashboard

## 📱 Paso 4: Actualizar Flutter App

Tu URL de Render será:
```
https://tracknarino-backend.onrender.com
```

Actualiza `trackarino_app/lib/config/api_config.dart`:

```dart
class ApiConfig {
  // En producción
  static const String baseUrl = 'https://tracknarino-backend.onrender.com';
  
  // En desarrollo
  // static const String baseUrl = 'http://10.0.2.2:4000'; // Emulador Android
  // static const String baseUrl = 'http://localhost:4000'; // Web/iOS
}
```

## ✅ Paso 5: Verificación

### Prueba tu API
```bash
curl https://tracknarino-backend.onrender.com/api/health
```

Deberías recibir:
```json
{
  "status": "OK",
  "timestamp": "2025-12-02T..."
}
```

### Prueba de autenticación
```bash
curl -X POST https://tracknarino-backend.onrender.com/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@test.com","password":"test123"}'
```

## 🐛 Solución de Problemas

### ❌ Error: "Build failed"
- Verifica que `package.json` tenga el script `start`
- Revisa los logs en Render Dashboard

### ❌ Error: "Cannot connect to MongoDB"
- Verifica que MONGO_URI esté correctamente copiado
- Confirma que MongoDB Atlas permite IPs de Render (0.0.0.0/0)

### ❌ Error: "Application failed to respond"
- Render usa el puerto 10000 por defecto
- Asegúrate que server.js use `process.env.PORT`

### ⚠️ Servicio en "Spin Down"
El plan gratuito de Render pone el servicio en suspensión después de 15 minutos de inactividad:
- Primera petición después de suspensión tarda ~30-60 segundos
- Esto es normal en el plan Free
- Considera usar un servicio de "ping" para mantenerlo activo

## 📊 Monitoreo

### Logs en Tiempo Real
En Render Dashboard → tu servicio → "Logs"

### Reiniciar Servicio
Render Dashboard → "Manual Deploy" → "Clear build cache & deploy"

## 🔒 Seguridad Post-Despliegue

1. **Cambiar JWT_SECRET**: Usa un valor único y seguro
2. **Variables Sensibles**: Nunca las subas a GitHub
3. **CORS**: Ya está configurado para aceptar Render
4. **Rate Limiting**: Considera añadir express-rate-limit

## 📈 Próximos Pasos

1. ✅ Desplegar backend en Render
2. ✅ Configurar MongoDB Atlas
3. ✅ Actualizar URL en Flutter
4. 📱 Generar APK con nueva URL
5. 🧪 Probar en dispositivo físico

---

## 🆘 Soporte

Si tienes problemas:
1. Revisa los logs en Render Dashboard
2. Verifica que MongoDB Atlas esté accesible
3. Confirma que las variables de entorno estén correctas
