# 🔥 Despliegue en Firebase Functions

## 📋 Requisitos
- Cuenta de Firebase (gratis)
- Firebase CLI instalado ✅

## 🚀 Pasos para Desplegar

### 1️⃣ Iniciar sesión en Firebase
```bash
cd c:\Users\dell\Desktop\Tesis\TracknarinoApp\Backend
firebase login
```

### 2️⃣ Inicializar proyecto Firebase
```bash
firebase init functions
```

**Configuración**:
- ¿Usar proyecto existente? → **Crear nuevo proyecto** o **Seleccionar existente**
- Language: **JavaScript**
- ESLint: **No**
- Install dependencies: **No** (ya las instalamos)

### 3️⃣ Configurar variables de entorno
```bash
firebase functions:config:set env.mongo_uri="mongodb+srv://guzdavid1108_db_user:eJBxFAjocy4LS2Gn@cluster0.z4lk362.mongodb.net/trackarino?retryWrites=true&w=majority&appName=Cluster0"

firebase functions:config:set env.jwt_secret="tracknarino_secret_key_2025_production"

firebase functions:config:set env.node_env="production"
```

### 4️⃣ Desplegar
```bash
firebase deploy --only functions
```

Tu URL será:
```
https://us-central1-<tu-proyecto-id>.cloudfunctions.net/api
```

## 📱 Actualizar Flutter

Edita `lib/config/api_config.dart`:
```dart
return 'https://us-central1-<tu-proyecto-id>.cloudfunctions.net/api/api';
```

## 🔧 Comandos Útiles

Ver logs:
```bash
firebase functions:log
```

Ver configuración:
```bash
firebase functions:config:get
```

Probar localmente:
```bash
firebase emulators:start
```

## 💰 Costos

Firebase Functions **Plan Gratuito**:
- ✅ 2 millones de invocaciones/mes
- ✅ 400,000 GB-segundos
- ✅ 200,000 GHz-segundos
- ✅ 5 GB de salida

Más que suficiente para tu app.

## ⚠️ Importante

1. MongoDB Atlas debe permitir conexiones desde Firebase:
   - Network Access → Allow Access from Anywhere (0.0.0.0/0)

2. CORS ya está configurado para Firebase en server.js

3. No uses `.env` en Firebase, usa `functions:config:set`

## 🐛 Solución de Problemas

**Error: Cannot find module**
```bash
cd Backend
npm install
firebase deploy --only functions
```

**Error: Billing account required**
- Firebase Functions requiere **Blaze Plan** (pago por uso)
- Pero tiene **capa gratuita generosa**
- Solo pagas si excedes los límites gratuitos
