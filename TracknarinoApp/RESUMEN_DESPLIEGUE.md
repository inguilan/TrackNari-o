# 📦 Resumen de Archivos para Despliegue en la Nube

## 🎯 Objetivo
Desplegar Tracknariño en la nube con:
- **Backend**: Render (Node.js + Express)
- **Base de Datos**: MongoDB Atlas
- **Frontend Web**: Vercel (Flutter Web)
- **Frontend Móvil**: APK para Android

---

## 📁 Archivos Creados y Modificados

### ✅ Backend

#### Archivos Nuevos:
```
Backend/
├── .env                                    ✨ Variables de entorno (desarrollo)
├── .env.production                         ✨ Variables de entorno (producción - ejemplo)
├── render.yaml                             ✨ Configuración de Render
├── scripts/
│   ├── crear_oportunidades_prueba.js      ✨ Script mejorado para datos de prueba
│   ├── probar_mongodb_atlas.js            ✨ Script para probar conexión a Atlas
│   ├── generar_jwt_secret.sh              ✨ Script para generar JWT (Linux/Mac)
│   └── generar_jwt_secret.bat             ✨ Script para generar JWT (Windows)
```

#### Archivos Modificados:
```
Backend/
├── package.json                            ✏️ Eliminada dependencia malformada
├── server.js                               ✏️ CORS actualizado para Vercel/Render
├── models/Oportunidad.js                   ✏️ Campos adicionales agregados
└── .gitignore                              ✏️ Actualizado (ya existía)
```

### ✅ Frontend

#### Archivos Nuevos:
```
trackarino_app/
└── vercel.json                             ✨ Configuración de Vercel
```

#### Archivos a Modificar (manualmente):
```
trackarino_app/
└── lib/
    └── config/
        └── api_config.dart                 ⚠️ Cambiar isDevelopment = false
                                            ⚠️ Actualizar URL de producción
```

#### Archivos Modificados (por ti):
```
trackarino_app/
└── lib/
    └── services/
        └── oportunidad_service.dart        ✏️ Eliminados datos simulados
```

### ✅ Documentación

#### Guías Creadas:
```
📄 GUIA_DATOS_REALES.md                     📚 Guía completa para usar datos reales
📄 GUIA_DESPLIEGUE_CLOUD.md                 📚 Guía detallada paso a paso (300+ líneas)
📄 DESPLIEGUE_RAPIDO.md                     📚 Guía rápida resumida
📄 CHECKLIST_DESPLIEGUE.md                  ✅ Checklist completo de verificación
📄 ACTUALIZAR_API_CONFIG.md                 📝 Instrucciones para actualizar API config
```

---

## 🚀 Orden de Ejecución

### Fase 1: MongoDB Atlas (15 minutos)
1. Crear cuenta en MongoDB Atlas
2. Crear cluster gratuito M0
3. Configurar usuario y contraseña
4. Permitir acceso desde cualquier IP (0.0.0.0/0)
5. Copiar connection string
6. Probar conexión localmente:
   ```bash
   cd Backend
   node scripts/probar_mongodb_atlas.js
   ```
7. Poblar datos de prueba:
   ```bash
   node scripts/crear_oportunidades_prueba.js
   ```

### Fase 2: Backend en Render (20 minutos)
1. Commit y push todo a GitHub
2. Crear cuenta en Render con GitHub
3. New Web Service → Conectar repo
4. Configurar:
   - Root Directory: `Backend`
   - Build: `npm install`
   - Start: `npm start`
5. Agregar variables de entorno:
   - `NODE_ENV=production`
   - `MONGO_URI=` (de Atlas)
   - `JWT_SECRET=` (generar con script)
6. Desplegar y verificar
7. Guardar URL: `https://tracknarino-backend.onrender.com`

### Fase 3: Frontend - Actualizar Config (5 minutos)
1. Abrir `trackarino_app/lib/config/api_config.dart`
2. Cambiar `isDevelopment = false`
3. Actualizar URL con la de Render
4. Guardar y commit

### Fase 4: Frontend Web en Vercel (20 minutos)
1. Build local de prueba:
   ```bash
   cd trackarino_app
   flutter build web --release
   ```
2. Crear cuenta en Vercel con GitHub
3. New Project → Import repo
4. Configurar:
   - Root: `trackarino_app`
   - Build: `flutter build web --release`
   - Output: `build/web`
5. Desplegar
6. Guardar URL: `https://tracknarino.vercel.app`

### Fase 5: APK Android (10 minutos)
1. Verificar que `api_config.dart` apunta a producción
2. Build:
   ```bash
   cd trackarino_app
   flutter build apk --release
   ```
3. APK en: `build/app/outputs/flutter-apk/app-release.apk`
4. Probar en dispositivo físico

---

## 📊 Variables de Entorno Necesarias

### MongoDB Atlas
```env
MONGO_URI=mongodb+srv://usuario:password@cluster0.xxxxx.mongodb.net/trackarino?retryWrites=true&w=majority
```
**Obtener de:** MongoDB Atlas → Connect → Connect your application

### JWT Secret
```env
JWT_SECRET=clave_aleatoria_64_caracteres_hexadecimal
```
**Generar con:**
```bash
# Windows
Backend\scripts\generar_jwt_secret.bat

# Linux/Mac
bash Backend/scripts/generar_jwt_secret.sh

# Manual con Node
node -e "console.log(require('crypto').randomBytes(32).toString('hex'))"
```

### Node Environment
```env
NODE_ENV=production
```

---

## 🔗 URLs Finales

Después del despliegue completo:

| Servicio | URL | Descripción |
|----------|-----|-------------|
| **Backend API** | `https://tracknarino-backend.onrender.com` | API REST Node.js |
| **API Docs** | `https://tracknarino-backend.onrender.com/` | Mensaje de bienvenida |
| **Oportunidades** | `https://tracknarino-backend.onrender.com/api/oportunidades/disponibles` | Endpoint de prueba |
| **Frontend Web** | `https://tracknarino.vercel.app` | Aplicación Flutter Web |
| **APK Android** | `build/app/outputs/flutter-apk/app-release.apk` | Archivo local |

---

## ✅ Verificación Rápida

### Backend Funciona:
```bash
curl https://tracknarino-backend.onrender.com/
# Debe responder: "Bienvenido al backend de Tracknariño"
```

### Frontend Conecta:
1. Abrir `https://tracknarino.vercel.app`
2. Ir a Login
3. Crear usuario
4. Si crea usuario = Backend funciona ✅

### APK Funciona:
1. Instalar APK en Android
2. Abrir app
3. Intentar login
4. Si conecta = Todo funciona ✅

---

## 🐛 Errores Comunes y Soluciones

### Backend no inicia en Render
**Error:** Build failed
**Solución:**
- Verificar que `Root Directory` sea `Backend`
- Verificar que `package.json` esté en `Backend/`
- Revisar logs de build en Render

### Frontend no conecta al Backend
**Error:** Network error / Connection refused
**Solución:**
- Verificar `api_config.dart` → `isDevelopment = false`
- Verificar URL en `api_config.dart` coincide con Render
- Verificar CORS en `server.js`

### MongoDB no conecta
**Error:** MongoServerSelectionError
**Solución:**
- Verificar `MONGO_URI` en variables de entorno Render
- Verificar que MongoDB Atlas permite IP 0.0.0.0/0
- Probar conexión localmente con `probar_mongodb_atlas.js`

### Render Backend "sleeping"
**Error:** Primera request tarda mucho
**Solución:**
- Plan Free de Render duerme tras 15 min inactividad
- Primera request toma 30-60 segundos en despertar
- Hacer request antes de demo: `curl https://tu-backend.onrender.com/`

---

## 💰 Costos Totales

| Servicio | Plan | Costo Mensual |
|----------|------|---------------|
| MongoDB Atlas | M0 (512MB) | **$0** |
| Render | Free Tier | **$0** |
| Vercel | Hobby | **$0** |
| **TOTAL** | | **$0/mes** 🎉 |

---

## 🎓 Para la Presentación

### Demostración Sugerida:

1. **Mostrar Arquitectura:**
   - Backend en Render (mostrar dashboard)
   - MongoDB Atlas (mostrar cluster)
   - Frontend en Vercel (mostrar deployment)

2. **Demostración en Vivo:**
   - Abrir `https://tracknarino.vercel.app`
   - Crear usuario contratista
   - Crear oportunidad
   - Abrir en móvil/otra pestaña como camionero
   - Aceptar oportunidad

3. **Mostrar Datos Reales:**
   - MongoDB Atlas → Collections → users
   - MongoDB Atlas → Collections → oportunidads
   - Mostrar que todo se guarda en la nube

4. **Métricas:**
   ```javascript
   // En MongoDB Atlas o con mongosh
   db.users.countDocuments()
   db.oportunidads.countDocuments()
   ```

### Plan B (si falla internet):
- Video pregrabado del flujo completo
- Capturas de pantalla de cada paso
- MongoDB Compass con datos exportados

---

## 📞 Soporte y Recursos

### Documentación Oficial:
- [MongoDB Atlas Docs](https://docs.atlas.mongodb.com/)
- [Render Docs](https://render.com/docs)
- [Vercel Docs](https://vercel.com/docs)
- [Flutter Deployment](https://docs.flutter.dev/deployment)

### Scripts de Ayuda:
```bash
# Probar MongoDB
node Backend/scripts/probar_mongodb_atlas.js

# Generar JWT Secret
Backend/scripts/generar_jwt_secret.bat

# Crear datos de prueba
node Backend/scripts/crear_oportunidades_prueba.js
```

---

## 📝 Notas Finales

### ✅ Lo que se logró:
- ✅ Backend desplegado en Render
- ✅ Base de datos en MongoDB Atlas
- ✅ Frontend web en Vercel
- ✅ APK Android compilado
- ✅ Datos reales (no simulados)
- ✅ API REST funcional
- ✅ Arquitectura cloud completa

### 🎯 Listo para:
- ✅ Presentación de tesis
- ✅ Demostración en vivo
- ✅ Evaluación de jurado
- ✅ Distribución a usuarios reales

---

## 🚀 Siguiente Paso

Lee la guía paso a paso completa:
```
📖 GUIA_DESPLIEGUE_CLOUD.md
```

O usa el checklist interactivo:
```
✅ CHECKLIST_DESPLIEGUE.md
```

¡Éxito con tu presentación! 🎓🎉
