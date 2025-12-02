# 🚀 Pasos Rápidos para Desplegar

## 1️⃣ MongoDB Atlas (5 minutos)

```bash
1. Ir a https://www.mongodb.com/cloud/atlas/register
2. Crear cuenta y cluster gratuito (M0)
3. Crear usuario de base de datos
4. Permitir acceso desde cualquier IP (0.0.0.0/0)
5. Copiar connection string:
   mongodb+srv://usuario:password@cluster0.xxxxx.mongodb.net/trackarino
```

## 2️⃣ Render - Backend (10 minutos)

```bash
1. Ir a https://render.com y registrarse con GitHub
2. New + → Web Service
3. Conectar repo: TracknarinoApp
4. Configuración:
   - Name: tracknarino-backend
   - Root Directory: Backend
   - Build Command: npm install
   - Start Command: npm start
   - Plan: Free

5. Variables de entorno:
   NODE_ENV=production
   MONGO_URI=tu_connection_string_de_mongodb_atlas
   JWT_SECRET=genera_una_clave_aleatoria_segura

6. Crear Web Service → Esperar despliegue
7. Tu backend estará en: https://tracknarino-backend.onrender.com
```

## 3️⃣ Actualizar Frontend con URL de Producción

Edita `trackarino_app/lib/config/api_config.dart`:

```dart
class ApiConfig {
  static bool isDevelopment = false; // ← CAMBIAR A FALSE
  
  static String get _baseUrl {
    if (isDevelopment) {
      // desarrollo...
    } else {
      // Producción - URL de Render
      return 'https://tracknarino-backend.onrender.com/api';
    }
  }
  // ...
}
```

## 4️⃣ Vercel - Frontend Web (10 minutos)

```bash
1. Construir versión web:
   cd trackarino_app
   flutter build web --release

2. Ir a https://vercel.com y registrarse con GitHub
3. New Project → Import TracknarinoApp
4. Configurar:
   - Framework: Other
   - Root Directory: trackarino_app
   - Build Command: flutter build web --release
   - Output Directory: build/web

5. Deploy → Esperar
6. Tu frontend estará en: https://tracknarino.vercel.app
```

## 5️⃣ Compilar APK para Android

```bash
cd trackarino_app
flutter build apk --release

# APK estará en:
# build/app/outputs/flutter-apk/app-release.apk
```

---

## ✅ VERIFICACIÓN

**Backend:**
```
https://tracknarino-backend.onrender.com/
```
→ Debe mostrar: "Bienvenido al backend de Tracknariño"

**Frontend Web:**
```
https://tracknarino.vercel.app/
```
→ Debe cargar la aplicación

**Probar login:**
- Crear usuario desde la app
- Iniciar sesión
- Ver oportunidades

---

## 🔧 Si algo falla:

**Render (Backend):**
- Ver logs en dashboard de Render
- Verificar variables de entorno
- Probar MONGO_URI localmente primero

**Vercel (Frontend):**
- Asegurarse de que `flutter build web` funciona localmente
- Ver logs de build en Vercel
- Verificar que `isDevelopment = false`

**CORS Error:**
- Actualizar dominios permitidos en `Backend/server.js`
- Ya están configurados Vercel y Render

---

## 📊 Costos: $0/mes

- MongoDB Atlas M0: Gratis
- Render Free Tier: Gratis
- Vercel Hobby: Gratis

---

## 🎯 URLs Finales

Después del despliegue tendrás:

- **API Backend**: `https://tracknarino-backend.onrender.com`
- **App Web**: `https://tracknarino.vercel.app`
- **APK**: Archivo local para distribuir

---

¡Listo para tu presentación de tesis! 🎓🚀
