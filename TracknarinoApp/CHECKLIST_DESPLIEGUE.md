# ✅ Checklist de Despliegue Tracknariño

Use esta lista para verificar cada paso del despliegue.

## 📋 Pre-Despliegue

### Preparación Local
- [ ] Node.js instalado (v18+)
- [ ] Flutter SDK instalado (v3+)
- [ ] Git configurado con GitHub
- [ ] Código funciona localmente
- [ ] Tests básicos realizados

### Limpieza de Código
- [ ] Eliminar `console.log()` innecesarios
- [ ] Eliminar código comentado
- [ ] Verificar que no hay credenciales hardcoded
- [ ] `.gitignore` actualizado (no incluir `.env` ni claves)

---

## 🗄️ MongoDB Atlas

### Crear Cluster
- [ ] Cuenta creada en mongodb.com
- [ ] Cluster M0 (FREE) creado
- [ ] Región seleccionada (us-east-1 recomendado)
- [ ] Cluster activo y funcionando

### Configurar Seguridad
- [ ] Usuario de base de datos creado
- [ ] Contraseña segura generada y guardada
- [ ] Network Access configurado (0.0.0.0/0 permitido)
- [ ] Connection String copiada

### Verificar Conexión
- [ ] URI probada localmente
- [ ] Script `probar_mongodb_atlas.js` ejecutado exitosamente
- [ ] Base de datos conecta correctamente

### Poblar Datos
- [ ] Script `crear_oportunidades_prueba.js` ejecutado
- [ ] Al menos 1 usuario contratista creado
- [ ] Al menos 3-5 oportunidades creadas
- [ ] Datos verificados en MongoDB Compass o Atlas UI

---

## 🖥️ Backend - Render

### Preparar Código
- [ ] `package.json` tiene scripts correctos
- [ ] `server.js` configurado para producción
- [ ] CORS actualizado con dominios de producción
- [ ] `.env.production` creado con valores de ejemplo
- [ ] `render.yaml` en la raíz de Backend/

### Configurar Render
- [ ] Cuenta creada en render.com
- [ ] Repositorio GitHub conectado
- [ ] Web Service creado
- [ ] Plan Free seleccionado

### Settings del Service
- [ ] Name: `tracknarino-backend`
- [ ] Region: Oregon (US West)
- [ ] Branch: `main`
- [ ] Root Directory: `Backend`
- [ ] Build Command: `npm install`
- [ ] Start Command: `npm start`

### Variables de Entorno
- [ ] `NODE_ENV` = `production`
- [ ] `MONGO_URI` = (tu URI de MongoDB Atlas)
- [ ] `JWT_SECRET` = (clave generada con script)
- [ ] `PORT` = `4000` (opcional, Render lo asigna)

### Desplegar y Verificar
- [ ] Deploy iniciado
- [ ] Build completado sin errores
- [ ] Service está "Live"
- [ ] URL funciona: `https://tracknarino-backend.onrender.com/`
- [ ] API responde: `https://tracknarino-backend.onrender.com/api/oportunidades/disponibles`

### Verificar Logs
- [ ] Logs muestran "Conectado a MongoDB"
- [ ] Logs muestran "Servidor corriendo"
- [ ] No hay errores críticos en logs

---

## 📱 Frontend - Configuración

### Actualizar para Producción
- [ ] Abrir `lib/config/api_config.dart`
- [ ] Cambiar `isDevelopment = false`
- [ ] Actualizar URL de producción con la de Render
- [ ] Verificar que todas las rutas usan `ApiConfig.baseUrl`

### Build Local (Prueba)
- [ ] `flutter clean` ejecutado
- [ ] `flutter pub get` ejecutado
- [ ] `flutter build web --release` exitoso
- [ ] Build funciona sin errores

### Commit y Push
- [ ] Cambios committed
- [ ] Push a rama `main` en GitHub
- [ ] GitHub muestra los últimos cambios

---

## 🌐 Frontend Web - Vercel

### Configurar Vercel
- [ ] Cuenta creada en vercel.com
- [ ] Repositorio GitHub conectado
- [ ] New Project creado

### Settings del Project
- [ ] Framework Preset: Other
- [ ] Root Directory: `trackarino_app`
- [ ] Build Command: `flutter build web --release`
- [ ] Output Directory: `build/web`
- [ ] Install Command configurado (Flutter)

### Desplegar y Verificar
- [ ] Deploy iniciado
- [ ] Build completado (puede tomar 5-10 min)
- [ ] Deployment está "Ready"
- [ ] URL funciona: `https://tracknarino.vercel.app/`
- [ ] App carga correctamente
- [ ] No hay errores en consola del navegador (F12)

### Probar Funcionalidad
- [ ] Página de login carga
- [ ] Página de registro carga
- [ ] Puede crear usuario nuevo
- [ ] Puede iniciar sesión
- [ ] Oportunidades cargan desde backend real
- [ ] Navegación funciona correctamente

---

## 📲 Frontend Móvil - APK Android

### Configurar para Release
- [ ] `api_config.dart` apunta a producción
- [ ] Versión actualizada en `pubspec.yaml`
- [ ] App name y package configurados

### Build APK
- [ ] `flutter clean` ejecutado
- [ ] `flutter build apk --release` exitoso
- [ ] APK generado en `build/app/outputs/flutter-apk/`
- [ ] APK tamaño razonable (<50 MB)

### Probar APK
- [ ] APK instalado en dispositivo Android físico
- [ ] App se abre correctamente
- [ ] Login funciona
- [ ] Conexión a backend funciona
- [ ] GPS y permisos funcionan (si aplica)

### Distribución (Opcional)
- [ ] APK renombrado (ej: `tracknarino_v1.0.0.apk`)
- [ ] APK compartido con evaluadores
- [ ] Instrucciones de instalación provistas

---

## 🔄 Post-Despliegue

### Verificación Final
- [ ] Backend responde correctamente
- [ ] Frontend web conecta al backend
- [ ] APK móvil conecta al backend
- [ ] CORS no bloquea peticiones
- [ ] Datos se guardan en MongoDB Atlas

### Testing Completo
- [ ] Registro de usuario funciona
- [ ] Login funciona
- [ ] Crear oportunidad funciona (contratista)
- [ ] Ver oportunidades funciona (camionero)
- [ ] Aceptar oportunidad funciona
- [ ] Actualización de estado funciona

### Monitoreo
- [ ] Render logs revisados (sin errores)
- [ ] Vercel logs revisados (sin errores)
- [ ] MongoDB Atlas metrics revisados
- [ ] URLs guardadas en documento

---

## 📊 Documentación para Tesis

### URLs Finales
- [ ] Backend API: `https://tracknarino-backend.onrender.com`
- [ ] Frontend Web: `https://tracknarino.vercel.app`
- [ ] APK ubicación: `build/app/outputs/flutter-apk/app-release.apk`

### Capturas de Pantalla
- [ ] Dashboard de Render con backend activo
- [ ] Dashboard de Vercel con frontend activo
- [ ] MongoDB Atlas con datos
- [ ] App web funcionando
- [ ] App móvil funcionando

### Videos de Demostración
- [ ] Video: Crear usuario y login
- [ ] Video: Crear oportunidad (contratista)
- [ ] Video: Aceptar oportunidad (camionero)
- [ ] Video: Flujo completo end-to-end

### Métricas
- [ ] Número de usuarios en BD
- [ ] Número de oportunidades en BD
- [ ] Tiempo de respuesta del API
- [ ] Tiempo de carga del frontend

---

## 🆘 Troubleshooting

### Si Backend no funciona:
- [ ] Verificar logs en Render
- [ ] Verificar MONGO_URI en variables de entorno
- [ ] Probar conexión a MongoDB Atlas localmente
- [ ] Verificar que MongoDB Atlas permite IP 0.0.0.0/0

### Si Frontend no conecta:
- [ ] Verificar URL en `api_config.dart`
- [ ] Verificar CORS en backend
- [ ] Verificar consola del navegador (F12)
- [ ] Probar endpoints con Postman

### Si hay errores de Build:
- [ ] Limpiar cache: `flutter clean`
- [ ] Reinstalar dependencias: `flutter pub get`
- [ ] Verificar versión de Flutter: `flutter doctor`
- [ ] Revisar logs de build en Render/Vercel

---

## 🎓 Preparación para Presentación

### Antes de Presentar
- [ ] Todos los items anteriores completados
- [ ] Plan B preparado (capturas, videos)
- [ ] Datos de prueba poblados
- [ ] URLs testeadas 1 día antes
- [ ] URLs testeadas 1 hora antes

### Durante Presentación
- [ ] URLs accesibles desde proyector
- [ ] Internet funciona correctamente
- [ ] Backend está "awake" (Render duerme tras 15 min)
- [ ] MongoDB Atlas activo y conectado

### Material de Respaldo
- [ ] Capturas de pantalla impresas/PDF
- [ ] Video de demostración disponible offline
- [ ] Presentación con arquitectura lista
- [ ] Métricas y estadísticas preparadas

---

## ✨ ¡Todo Listo!

Si todos los items están marcados, tu aplicación está **100% lista para producción** y para tu presentación de tesis. 

**URLs para compartir:**
- API: `https://tracknarino-backend.onrender.com`
- Web: `https://tracknarino.vercel.app`

¡Éxito en tu presentación! 🎉🎓
