# 🚀 Guía Completa de Despliegue en la Nube

Esta guía te llevará paso a paso para desplegar tu aplicación Tracknariño en producción.

## 📋 Resumen del Despliegue

- **Backend**: Render (Node.js)
- **Base de Datos**: MongoDB Atlas (Cloud)
- **Frontend Web**: Vercel (Flutter Web)
- **Frontend Móvil**: Compilar APK/IPA

---

## 🗄️ PARTE 1: Configurar MongoDB Atlas

### Paso 1: Crear Cuenta en MongoDB Atlas

1. Ve a [https://www.mongodb.com/cloud/atlas/register](https://www.mongodb.com/cloud/atlas/register)
2. Regístrate con tu email o Google
3. Completa el formulario inicial

### Paso 2: Crear un Cluster Gratuito

1. Selecciona **"Build a Database"**
2. Elige **M0 (FREE)** - 512 MB de almacenamiento
3. Selecciona **Provider**: AWS
4. **Region**: us-east-1 (o la más cercana)
5. **Cluster Name**: `Cluster0` (o el nombre que prefieras)
6. Click en **"Create Cluster"**

### Paso 3: Configurar Usuario de Base de Datos

1. En el menú lateral, ve a **"Database Access"**
2. Click en **"Add New Database User"**
3. Selecciona **"Password"** como método de autenticación
4. **Username**: `tracknarino_user` (o el que prefieras)
5. **Password**: Genera una contraseña segura (guárdala)
6. **Database User Privileges**: Selecciona **"Read and write to any database"**
7. Click en **"Add User"**

### Paso 4: Configurar Acceso desde Cualquier IP

1. En el menú lateral, ve a **"Network Access"**
2. Click en **"Add IP Address"**
3. Selecciona **"Allow Access from Anywhere"** (0.0.0.0/0)
4. Click en **"Confirm"**

> ⚠️ **Nota de Seguridad**: En producción real, deberías agregar solo las IPs específicas de Render.

### Paso 5: Obtener la Connection String

1. Ve a **"Database"** → **"Connect"**
2. Selecciona **"Connect your application"**
3. Selecciona **Driver**: Node.js, **Version**: 4.1 or later
4. Copia la connection string, se verá algo así:
   ```
   mongodb+srv://tracknarino_user:<password>@cluster0.xxxxx.mongodb.net/?retryWrites=true&w=majority
   ```
5. **Reemplaza `<password>`** con la contraseña real del usuario
6. **Agrega el nombre de la base de datos** después de `.net/`:
   ```
   mongodb+srv://tracknarino_user:tuPassword123@cluster0.xxxxx.mongodb.net/trackarino?retryWrites=true&w=majority
   ```

### Paso 6: Crear Datos Iniciales (Opcional)

Una vez tengas la connection string, puedes poblar la base de datos:

1. En tu computadora local, actualiza el `.env`:
   ```env
   MONGO_URI=mongodb+srv://tracknarino_user:tuPassword@cluster0.xxxxx.mongodb.net/trackarino?retryWrites=true&w=majority
   ```

2. Ejecuta el script de datos de prueba:
   ```bash
   cd Backend
   node scripts/crear_oportunidades_prueba.js --auto
   ```

---

## 🖥️ PARTE 2: Desplegar Backend en Render

### Paso 1: Preparar el Código

1. Asegúrate de que tu código esté en GitHub:
   ```bash
   cd "C:\Users\dell\Desktop\Tesis\TracknarinoApp"
   git add .
   git commit -m "Preparar para despliegue en Render"
   git push origin main
   ```

2. Verifica que existan estos archivos en `Backend/`:
   - ✅ `package.json`
   - ✅ `server.js`
   - ✅ `.env.production` (ejemplo)
   - ✅ `render.yaml` (opcional)

### Paso 2: Crear Cuenta en Render

1. Ve a [https://render.com](https://render.com)
2. Regístrate con GitHub (recomendado)
3. Autoriza a Render para acceder a tus repositorios

### Paso 3: Crear Web Service

1. En el dashboard, click en **"New +"** → **"Web Service"**
2. Conecta tu repositorio de GitHub: `TracknarinoApp`
3. Configura el servicio:

   **Basic Settings:**
   - **Name**: `tracknarino-backend`
   - **Region**: Oregon (US West) - es gratis
   - **Branch**: `main`
   - **Root Directory**: `Backend`
   - **Runtime**: `Node`
   - **Build Command**: `npm install`
   - **Start Command**: `npm start`

   **Instance Type:**
   - Selecciona **"Free"** (750 horas gratis al mes)

### Paso 4: Configurar Variables de Entorno

En la sección **"Environment Variables"**, agrega:

| Key | Value |
|-----|-------|
| `NODE_ENV` | `production` |
| `MONGO_URI` | `mongodb+srv://tracknarino_user:tuPassword@cluster0.xxxxx.mongodb.net/trackarino?retryWrites=true&w=majority` |
| `JWT_SECRET` | Una cadena aleatoria segura (ej: `jT9kL3mN8pQ2rS5vW7xY0zA`) |
| `PORT` | `4000` (Render lo sobreescribirá automáticamente) |

> 💡 **Tip**: Para generar JWT_SECRET seguro, usa:
> ```bash
> node -e "console.log(require('crypto').randomBytes(32).toString('hex'))"
> ```

### Paso 5: Desplegar

1. Click en **"Create Web Service"**
2. Render comenzará a construir y desplegar automáticamente
3. Espera 5-10 minutos a que termine el despliegue
4. Verás la URL de tu backend: `https://tracknarino-backend.onrender.com`

### Paso 6: Verificar el Despliegue

Abre en el navegador:
```
https://tracknarino-backend.onrender.com/
```

Deberías ver: **"Bienvenido al backend de Tracknariño"**

Verifica la API:
```
https://tracknarino-backend.onrender.com/api/oportunidades/disponibles
```

---

## 📱 PARTE 3: Desplegar Frontend Web en Vercel

### Paso 1: Preparar Flutter para Web

1. Actualiza `api_config.dart` para producción:

```dart
class ApiConfig {
  static bool isDevelopment = false; // CAMBIAR A FALSE
  
  static String get _baseUrl {
    if (isDevelopment) {
      // ... código de desarrollo
    } else {
      // URL de producción de Render
      return 'https://tracknarino-backend.onrender.com/api';
    }
  }
  // ... resto del código
}
```

2. Construye la versión web:
```bash
cd trackarino_app
flutter build web --release
```

### Paso 2: Crear Cuenta en Vercel

1. Ve a [https://vercel.com/signup](https://vercel.com/signup)
2. Regístrate con GitHub
3. Autoriza a Vercel

### Paso 3: Desplegar en Vercel

**Opción A: Desde la Web (Recomendado)**

1. En Vercel dashboard, click **"Add New"** → **"Project"**
2. Importa tu repositorio `TracknarinoApp`
3. Configura el proyecto:
   - **Framework Preset**: Other
   - **Root Directory**: `trackarino_app`
   - **Build Command**: `flutter build web --release`
   - **Output Directory**: `build/web`
   - **Install Command**: 
     ```bash
     git clone https://github.com/flutter/flutter.git -b stable --depth 1 && 
     export PATH="$PATH:$PWD/flutter/bin" && 
     flutter doctor && 
     flutter pub get
     ```

4. Click **"Deploy"**

**Opción B: Desde la Terminal (CLI)**

```bash
cd trackarino_app

# Instalar Vercel CLI
npm install -g vercel

# Login
vercel login

# Desplegar
vercel --prod
```

### Paso 4: Configurar Dominio (Opcional)

Vercel te dará un dominio como: `https://tracknarino.vercel.app`

Si tienes dominio propio:
1. Ve a **Settings** → **Domains**
2. Agrega tu dominio
3. Configura los DNS según las instrucciones

---

## 📲 PARTE 4: Compilar APK para Android

### Para Publicar en Google Play Store:

1. **Genera la keystore**:
```bash
cd trackarino_app/android
keytool -genkey -v -keystore tracknarino-release.keystore -alias tracknarino -keyalg RSA -keysize 2048 -validity 10000
```

2. **Configura `key.properties`**:
```bash
# En android/key.properties
storePassword=tuPassword
keyPassword=tuPassword
keyAlias=tracknarino
storeFile=tracknarino-release.keystore
```

3. **Actualiza `build.gradle`** (android/app/build.gradle):
```gradle
android {
    ...
    signingConfigs {
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
            storePassword keystoreProperties['storePassword']
        }
    }
    buildTypes {
        release {
            signingConfig signingConfigs.release
        }
    }
}
```

4. **Compila el APK**:
```bash
flutter build apk --release
```

El APK estará en: `build/app/outputs/flutter-apk/app-release.apk`

### Para Distribución Directa (Sin Play Store):

```bash
# APK simple (más grande)
flutter build apk --release

# App Bundle (para Play Store)
flutter build appbundle --release
```

---

## 🍎 PARTE 5: Compilar IPA para iOS (Solo Mac)

```bash
# Abre Xcode
open ios/Runner.xcworkspace

# O desde terminal
flutter build ios --release
```

---

## ⚙️ CONFIGURACIÓN ADICIONAL

### Actualizar CORS en el Backend

Edita `Backend/server.js` para permitir tu dominio de Vercel:

```javascript
app.use(cors({
  origin: function(origin, callback) {
    const allowedOrigins = [
      'http://localhost:3000',
      'https://tracknarino.vercel.app', // Tu dominio de Vercel
      'https://tracknarino-backend.onrender.com'
    ];
    
    if (!origin || allowedOrigins.indexOf(origin) !== -1) {
      return callback(null, true);
    }
    
    return callback(new Error('Origen no permitido por CORS'));
  },
  credentials: true
}));
```

Commit y push:
```bash
git add .
git commit -m "Actualizar CORS para producción"
git push origin main
```

Render se actualizará automáticamente.

---

## 🔄 FLUJO DE ACTUALIZACIÓN

### Actualizar Backend:
```bash
cd Backend
# Hacer cambios
git add .
git commit -m "Actualización backend"
git push origin main
# Render desplegará automáticamente
```

### Actualizar Frontend Web:
```bash
cd trackarino_app
# Hacer cambios
flutter build web --release
git add .
git commit -m "Actualización frontend"
git push origin main
# Vercel desplegará automáticamente
```

### Actualizar APK Móvil:
```bash
cd trackarino_app
flutter build apk --release
# Distribuir el nuevo APK manualmente
```

---

## 🐛 SOLUCIÓN DE PROBLEMAS

### Error: "Cannot connect to backend"
- Verifica que la URL en `api_config.dart` sea correcta
- Revisa los logs en Render dashboard
- Verifica CORS

### Error: "MongoDB connection failed"
- Verifica que la `MONGO_URI` esté correcta
- Asegúrate de que la IP 0.0.0.0/0 esté permitida en MongoDB Atlas
- Verifica usuario y contraseña

### Render: "Build failed"
- Revisa los logs de build en Render
- Verifica que `package.json` tenga `"start": "nodemon server.js"` o `"start": "node server.js"`
- Asegúrate de que `Root Directory` sea `Backend`

### Vercel: "Build failed"
- Asegúrate de que Flutter esté instalado en el build
- Verifica que la versión de Flutter sea compatible
- Revisa logs de build en Vercel

---

## 📊 MONITOREO Y LOGS

### Backend (Render):
- Ve al dashboard de Render
- Selecciona tu servicio
- Click en **"Logs"** para ver logs en tiempo real

### Frontend (Vercel):
- Ve al dashboard de Vercel
- Selecciona tu proyecto
- Click en **"Deployments"** → Ver logs

### MongoDB Atlas:
- Ve a **"Metrics"** en el cluster
- Puedes ver conexiones, operaciones, etc.

---

## 💰 COSTOS

| Servicio | Plan Gratuito | Límites |
|----------|---------------|---------|
| **MongoDB Atlas** | M0 (FREE) | 512 MB almacenamiento |
| **Render** | Free Tier | 750 horas/mes, sleep después de 15 min inactividad |
| **Vercel** | Hobby (FREE) | 100 GB bandwidth/mes, builds ilimitados |

**Total mensual: $0 USD** 🎉

---

## 🚀 URLs FINALES

Después del despliegue, tendrás:

- **Backend API**: `https://tracknarino-backend.onrender.com`
- **Frontend Web**: `https://tracknarino.vercel.app`
- **APK Android**: Archivo local para distribuir

---

## 📝 CHECKLIST PRE-DESPLIEGUE

Antes de desplegar, verifica:

- [ ] MongoDB Atlas configurado con usuario y contraseña
- [ ] Connection string probada localmente
- [ ] Variables de entorno preparadas
- [ ] `isDevelopment = false` en `api_config.dart`
- [ ] CORS actualizado con dominios de producción
- [ ] Código committed y pushed a GitHub
- [ ] Flutter web construido correctamente
- [ ] API probada con Postman/curl

---

## 🎓 PARA TU PRESENTACIÓN DE TESIS

### URLs para Demostrar:

**Backend:**
```
https://tracknarino-backend.onrender.com/
https://tracknarino-backend.onrender.com/api/oportunidades/disponibles
```

**Frontend:**
```
https://tracknarino.vercel.app/
```

### Puntos a Destacar:

✅ Arquitectura en la nube (Cloud-native)  
✅ Escalabilidad con MongoDB Atlas  
✅ CI/CD automático con Render y Vercel  
✅ API RESTful desplegada en producción  
✅ Frontend web accesible desde cualquier dispositivo  
✅ APK móvil para Android  

---

## 📞 SOPORTE

Si tienes problemas durante el despliegue:

1. Revisa los logs en Render/Vercel
2. Verifica las variables de entorno
3. Prueba la conexión a MongoDB Atlas localmente
4. Revisa la consola del navegador (F12)

¡Buena suerte con el despliegue! 🚀
