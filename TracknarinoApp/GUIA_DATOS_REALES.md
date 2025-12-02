# 🚀 Guía para Ejecutar Tracknariño con Datos Reales

Esta guía te ayudará a poner en funcionamiento el backend y frontend de Tracknariño con datos reales para tu presentación de tesis.

## 📋 Requisitos Previos

### Software Necesario:
1. **Node.js** (versión 18 o superior) - [Descargar](https://nodejs.org/)
2. **MongoDB** (versión 5.0 o superior) - [Descargar](https://www.mongodb.com/try/download/community)
3. **Flutter SDK** (versión 3.0 o superior) - [Descargar](https://flutter.dev/docs/get-started/install)
4. **Git** - [Descargar](https://git-scm.com/downloads)

### Verificar Instalación:
```bash
node --version
npm --version
mongod --version
flutter --version
```

---

## 🔧 Parte 1: Configurar y Arrancar el Backend

### 1.1 Navegar a la carpeta del Backend
```bash
cd /d "C:\Users\dell\Desktop\Tesis\TracknarinoApp\Backend"
```

### 1.2 Instalar Dependencias
```bash
npm install
```

### 1.3 Iniciar MongoDB
Abre una **nueva ventana de terminal** y ejecuta:

**Opción A - Si MongoDB está instalado como servicio:**
```bash
net start MongoDB
```

**Opción B - Si instalaste MongoDB manualmente:**
```bash
"C:\Program Files\MongoDB\Server\7.0\bin\mongod.exe" --dbpath "C:\data\db"
```

> **Nota**: Asegúrate de que la carpeta `C:\data\db` existe. Si no, créala con:
> ```bash
> mkdir C:\data\db
> ```

### 1.4 Configurar Variables de Entorno
El archivo `.env` ya está configurado con valores por defecto. Si necesitas cambiar algo:

```env
PORT=4000
MONGO_URI=mongodb://localhost:27017/trackarino
JWT_SECRET=tracknarino_secret_key_2025_desarrollo
NODE_ENV=development
```

### 1.5 Iniciar el Servidor Backend
```bash
npm start
```

**Verificar que funciona:**
- Abre un navegador en: `http://localhost:4000/`
- Deberías ver: **"Bienvenido al backend de Tracknariño"**

---

## 📱 Parte 2: Configurar y Arrancar el Frontend Flutter

### 2.1 Navegar a la carpeta del Frontend
```bash
cd /d "C:\Users\dell\Desktop\Tesis\TracknarinoApp\trackarino_app"
```

### 2.2 Instalar Dependencias Flutter
```bash
flutter pub get
```

### 2.3 Verificar Configuración de API
El frontend ya está configurado para conectarse al backend local. Verifica en `lib/config/api_config.dart`:

```dart
static bool isDevelopment = true; // ✅ Debe estar en true
```

Esto configurará automáticamente:
- **Android Emulator**: `http://10.0.2.2:4000/api`
- **iOS Simulator**: `http://localhost:4000/api`
- **Web**: `http://localhost:4000/api`

### 2.4 Ejecutar la Aplicación

**Para Android:**
```bash
flutter run -d android
```

**Para iOS (solo en Mac):**
```bash
flutter run -d ios
```

**Para Web:**
```bash
flutter run -d chrome
```

**Para Windows:**
```bash
flutter run -d windows
```

---

## 🧪 Parte 3: Probar el Sistema con Datos Reales

### 3.1 Crear Datos de Prueba
El backend tiene un script para crear oportunidades de prueba:

```bash
cd /d "C:\Users\dell\Desktop\Tesis\TracknarinoApp\Backend"
node scripts/crear_oportunidades_narino.js
```

O crea datos manualmente desde el frontend:

### 3.2 Flujo de Prueba Completo

#### A. Registro de Usuarios

**1. Registrar un Contratista:**
- Abre la app Flutter
- Ve a "Registrarse"
- Completa los datos:
  - Tipo: **Contratista**
  - Nombre: Tu nombre
  - Correo: `contratista@test.com`
  - Contraseña: `123456`
  - Empresa: `Transportes del Sur`
  - Teléfono: `3001234567`

**2. Registrar un Camionero:**
- Cierra sesión
- Registra otro usuario:
  - Tipo: **Camionero**
  - Nombre: Otro nombre
  - Correo: `camionero@test.com`
  - Contraseña: `123456`
  - Número de cédula: `12345678`
  - Empresa afiliada: `Transportes del Sur`
  - Licencia expedición: `Nariño`
  - Camión: `ABC-123, Chevrolet, 10 toneladas`

#### B. Crear Oportunidades (Como Contratista)

1. Inicia sesión como `contratista@test.com`
2. Ve a "Crear Oportunidad"
3. Completa los datos:
   - Título: `Transporte de productos agrícolas`
   - Origen: `Pasto`
   - Destino: `Cali`
   - Precio: `800000`
   - Peso: `5` toneladas
   - Tipo de carga: `Productos agrícolas`
   - Dirección cargue: `Calle 20 # 15-30, Pasto`
   - Dirección descargue: `Carrera 15 # 45-12, Cali`
4. Presiona "Crear"

#### C. Aceptar Oportunidades (Como Camionero)

1. Cierra sesión
2. Inicia sesión como `camionero@test.com`
3. Ve a "Oportunidades Disponibles"
4. Verás las oportunidades creadas por el contratista
5. Presiona en una oportunidad
6. Presiona "Aceptar Oportunidad"

#### D. Seguimiento en Tiempo Real

1. Como camionero, ve a "Mi Viaje"
2. Verás la ruta en el mapa
3. Presiona "Iniciar Viaje"
4. La ubicación se actualizará automáticamente

---

## 🐛 Solución de Problemas Comunes

### Error: "No se puede conectar al backend"
**Solución:**
1. Verifica que el backend está corriendo: `http://localhost:4000/`
2. Verifica que MongoDB está corriendo
3. En Android Emulator, asegúrate de usar `10.0.2.2` en lugar de `localhost`

### Error: "Error al obtener oportunidades"
**Solución:**
1. Verifica que iniciaste sesión correctamente
2. Revisa la consola del backend para ver errores
3. Asegúrate de que hay oportunidades creadas en la base de datos

### Error: MongoDB no inicia
**Solución:**
1. Crea la carpeta de datos: `mkdir C:\data\db`
2. Dale permisos completos a la carpeta
3. Ejecuta MongoDB manualmente como administrador

### Error: "Token expirado" o "No autorizado"
**Solución:**
1. Cierra sesión en la app
2. Vuelve a iniciar sesión
3. El token se renovará automáticamente

### Error al instalar dependencias en Backend
**Solución:**
```bash
# Elimina node_modules y vuelve a instalar
rm -rf node_modules
rm package-lock.json
npm install
```

---

## 📊 Verificar Datos en MongoDB

Para ver los datos almacenados en MongoDB:

### Usando MongoDB Compass (GUI)
1. Descarga [MongoDB Compass](https://www.mongodb.com/try/download/compass)
2. Conéctate a: `mongodb://localhost:27017`
3. Ve a la base de datos `trackarino`
4. Verás las colecciones: `users`, `oportunidads`, `ubicacions`, etc.

### Usando MongoDB Shell (CLI)
```bash
mongosh

use trackarino

# Ver usuarios
db.users.find().pretty()

# Ver oportunidades
db.oportunidads.find().pretty()

# Contar documentos
db.users.countDocuments()
db.oportunidads.countDocuments()
```

---

## 🚀 Consejos para la Presentación de Tesis

### 1. **Demostración en Vivo**
- Prepara datos de prueba con antelación
- Ten abiertas 2 instancias de la app (o 2 dispositivos):
  - Una como Contratista
  - Otra como Camionero
- Muestra el flujo completo: Crear → Aceptar → Iniciar viaje

### 2. **Capturas de Pantalla y Videos**
- Graba videos cortos de cada funcionalidad
- Toma capturas de pantalla de las pantallas principales
- Prepara diagramas de la arquitectura

### 3. **Plan B por si falla la conexión**
- Ten capturas de pantalla listas
- Graba un video de demostración completo
- Prepara slides con screenshots

### 4. **Datos Realistas**
- Usa nombres de empresas reales de Nariño
- Usa rutas reales (Pasto-Cali, Ipiales-Bogotá, etc.)
- Usa precios realistas según distancia

### 5. **Métricas para Mostrar**
```bash
# Consultas útiles para estadísticas

# Total de usuarios
db.users.countDocuments()

# Usuarios por tipo
db.users.aggregate([
  { $group: { _id: "$tipoUsuario", count: { $sum: 1 } } }
])

# Oportunidades por estado
db.oportunidads.aggregate([
  { $group: { _id: "$estado", count: { $sum: 1 } } }
])

# Precio promedio de oportunidades
db.oportunidads.aggregate([
  { $group: { _id: null, promedio: { $avg: "$precio" } } }
])
```

---

## 📝 Notas Adicionales

### Cambios Realizados para Datos Reales:
✅ **Backend:**
- Corregido `package.json` (eliminada dependencia malformada)
- Agregado archivo `.env` con configuración por defecto
- Actualizado modelo `Oportunidad.js` con campos adicionales

✅ **Frontend:**
- Eliminado método `_generarOportunidadesSimuladas()` en `oportunidad_service.dart`
- Corregidos endpoints para usar `/disponibles` en lugar de raíz
- Corregido método `aplicarOportunidad` para usar `PUT /:id/aceptar`
- Mejorado manejo de errores y logs en modo debug

### Estructura de la Base de Datos:
- **users**: Contratistas y Camioneros
- **oportunidads**: Cargas/viajes
- **ubicacions**: Ubicaciones en tiempo real
- **alertaseguridads**: Alertas de seguridad
- **calificacions**: Calificaciones de usuarios

---

## 🎓 ¡Éxito en tu Presentación!

Si tienes problemas, revisa:
1. Consola del backend (terminal donde corre Node.js)
2. Logs de Flutter (en la terminal o VS Code Debug Console)
3. Logs de MongoDB (si MongoDB está en terminal)

**Comando útil para ver logs en tiempo real:**
```bash
# En el backend
npm start

# Los logs mostrarán cada petición HTTP
```

---

## 📞 Contacto y Soporte

Para cualquier duda durante la implementación:
- Revisa los logs del backend en la terminal
- Usa `flutter run -v` para ver logs detallados
- Verifica que todas las dependencias estén instaladas correctamente

¡Buena suerte con tu tesis! 🎉
