# TracknariñoApp Backend - Railway Deployment

Este es el backend de la aplicación TracknariñoApp desplegado en Railway.

## 🚀 Despliegue en Railway

### Variables de Entorno Requeridas

En el dashboard de Railway, configura las siguientes variables:

```
MONGO_URI=mongodb+srv://guzdavid1108_db_user:eJBxFAjocy4LS2Gn@cluster0.z4lk362.mongodb.net/trackarino?retryWrites=true&w=majority&appName=Cluster0
JWT_SECRET=tracknarino_secret_key_2025_desarrollo
NODE_ENV=production
PORT=4000
```

### URL del Servicio

Una vez desplegado, Railway te proporcionará una URL como:
```
https://tu-proyecto.up.railway.app
```

## 📝 Instrucciones de Despliegue

1. Ve a [Railway.app](https://railway.app)
2. Inicia sesión con GitHub
3. Clic en "New Project"
4. Selecciona "Deploy from GitHub repo"
5. Autoriza Railway a acceder a tu repositorio
6. Selecciona el repositorio `TracknarinoApp`
7. Railway detectará automáticamente el backend
8. Configura las variables de entorno (arriba)
9. El despliegue se iniciará automáticamente

## 🔧 Configuración Post-Despliegue

### 1. Actualiza la URL en tu app Flutter

Edita `lib/config/api_config.dart`:

```dart
class ApiConfig {
  static const String baseUrl = 'https://TU-URL-DE-RAILWAY.up.railway.app';
  // ... resto del código
}
```

### 2. Prueba los endpoints

```bash
# Health check
curl https://TU-URL-DE-RAILWAY.up.railway.app/

# Auth test
curl https://TU-URL-DE-RAILWAY.up.railway.app/api/auth/test
```

## 📊 Monitoreo

Railway proporciona:
- Logs en tiempo real
- Métricas de uso
- Reinicio automático en caso de fallo
- Despliegue automático con cada push a main

## 🔄 Actualizaciones

Cada vez que hagas push a tu rama main en GitHub, Railway redespliegará automáticamente.

## 💰 Plan Gratuito

Railway ofrece:
- $5 de crédito gratuito al mes
- 500 horas de ejecución
- Suficiente para desarrollo y pruebas

## 🐛 Troubleshooting

### El servidor no arranca
- Verifica que todas las variables de entorno estén configuradas
- Revisa los logs en Railway dashboard
- Verifica que la conexión a MongoDB Atlas esté permitida desde cualquier IP

### CORS errors
- El backend ya está configurado para aceptar requests desde Railway
- Verifica que la URL en Flutter coincida con la de Railway

### MongoDB connection failed
- Verifica que la IP de Railway esté en la whitelist de MongoDB Atlas
- O configura MongoDB Atlas para permitir conexiones desde cualquier IP (0.0.0.0/0)
