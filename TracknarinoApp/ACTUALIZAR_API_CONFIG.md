# 📝 Instrucciones: Actualizar api_config.dart para Producción

Después de desplegar el backend en Render, debes actualizar el frontend para que apunte a la URL de producción.

## 🎯 Paso 1: Obtener la URL de Render

Después de desplegar en Render, tu backend tendrá una URL como:
```
https://tracknarino-backend.onrender.com
```

## ✏️ Paso 2: Editar api_config.dart

Abre el archivo:
```
trackarino_app/lib/config/api_config.dart
```

Realiza estos cambios:

### ANTES (Desarrollo):
```dart
class ApiConfig {
  static bool isDevelopment = true;  // ← CAMBIAR ESTO
  
  static String get _baseUrl {
    if (isDevelopment) {
      // código de desarrollo...
    } else {
      // URL de producción
      return 'https://api.trackarino.com/api';  // ← Y ESTO
    }
  }
  // ...
}
```

### DESPUÉS (Producción):
```dart
class ApiConfig {
  static bool isDevelopment = false;  // ← FALSE para producción
  
  static String get _baseUrl {
    if (isDevelopment) {
      // código de desarrollo...
    } else {
      // URL de producción - REEMPLAZAR con tu URL de Render
      return 'https://tracknarino-backend.onrender.com/api';  // ← Tu URL aquí
    }
  }
  // ...
}
```

## 📋 Archivo Completo con Cambios:

```dart
import 'dart:io';
import 'package:flutter/foundation.dart';

class ApiConfig {
  // ⚠️ IMPORTANTE: Cambiar a false para producción
  static bool isDevelopment = false;  // ← CAMBIO 1: true → false
  
  // Determinar la URL base correcta según la plataforma
  static String get _baseUrl {
    if (isDevelopment) {
      // Desarrollo - Servidor local
      if (kIsWeb) {
        return 'http://localhost:4000/api';
      } else if (Platform.isAndroid) {
        return 'http://10.0.2.2:4000/api'; // Para emulador Android
      } else {
        return 'http://localhost:4000/api'; // Para iOS o escritorio
      }
    } else {
      // ⚠️ PRODUCCIÓN - Reemplazar con tu URL de Render
      return 'https://tracknarino-backend.onrender.com/api';  // ← CAMBIO 2: Tu URL
    }
  }

  // Permitir acceso público a la URL base
  static String get baseUrl => _baseUrl;

  // Rutas de API
  static String get auth => '$_baseUrl/auth';
  static String get users => '$_baseUrl/users';
  static String get oportunidades => '$_baseUrl/oportunidades';
  static String get ubicacion => '$_baseUrl/ubicacion';
  static String get alertas => '$_baseUrl/alertas';
  
  // Rutas de autenticación
  static String get login => '$auth/login';
  static String get register => '$auth/register';
  
  // Tiempo de espera para solicitudes API
  static const int timeoutSeconds = 30;
  
  // Token de API de Google Maps (opcional)
  static const String googleMapsApiKey = 'YOUR_GOOGLE_MAPS_API_KEY';
  
  // Parámetros de autenticación
  static const String tokenKey = 'auth_token';
} 
```

## ✅ Paso 3: Verificar los Cambios

Después de hacer los cambios:

1. **Guardar el archivo**
2. **Ejecutar flutter clean** (opcional pero recomendado):
   ```bash
   cd trackarino_app
   flutter clean
   flutter pub get
   ```

3. **Probar localmente** que apunte a producción:
   ```bash
   flutter run -d chrome
   # O
   flutter run -d android
   ```

4. **Verificar en la app**:
   - Abre las Developer Tools (F12)
   - Ve a la consola
   - Al hacer login deberías ver requests a tu URL de Render:
     ```
     GET REQUEST: https://tracknarino-backend.onrender.com/api/auth/login
     ```

## 🏗️ Paso 4: Build para Producción

Una vez verificado que funciona:

### Para Web (Vercel):
```bash
flutter build web --release
```

### Para Android APK:
```bash
flutter build apk --release
```

## 🔄 Volver a Desarrollo

Si necesitas volver a trabajar en local, simplemente cambia:
```dart
static bool isDevelopment = true;  // ← Volver a true
```

## 💡 Tips

### Usar Variables de Entorno (Avanzado)

Si quieres cambiar fácilmente entre desarrollo y producción, puedes usar:

```dart
class ApiConfig {
  // Lee desde variable de entorno o usa valor por defecto
  static bool isDevelopment = 
      const bool.fromEnvironment('DEV', defaultValue: false);
  
  // ...
}
```

Luego compila con:
```bash
# Para desarrollo
flutter run --dart-define=DEV=true

# Para producción
flutter build web --dart-define=DEV=false
```

### Múltiples Ambientes

Para proyectos más grandes, puedes tener:
```dart
enum Environment { dev, staging, production }

class ApiConfig {
  static const Environment currentEnv = Environment.production;
  
  static String get _baseUrl {
    switch (currentEnv) {
      case Environment.dev:
        return 'http://localhost:4000/api';
      case Environment.staging:
        return 'https://staging-backend.onrender.com/api';
      case Environment.production:
        return 'https://tracknarino-backend.onrender.com/api';
    }
  }
}
```

## ⚠️ Importante: No Comitear Claves Secretas

Si usas Google Maps API Key u otras claves:
1. No las pongas directamente en el código
2. Usa variables de entorno
3. Agrega el archivo al `.gitignore`

## 🆘 Solución de Problemas

### Error: "Connection refused" o "Failed to connect"
- Verifica que `isDevelopment = false`
- Verifica que la URL de Render esté correcta
- Verifica que el backend en Render esté "Live"

### Error: "CORS policy" 
- Verifica que el backend tenga configurado CORS para tu dominio
- El archivo `Backend/server.js` ya incluye configuración para Vercel

### Backend está "sleeping" (Render Free Tier)
- Render duerme el backend tras 15 min de inactividad
- Primera request puede tardar 30-60 segundos en "despertar"
- Haz una request inicial antes de la demo: 
  ```
  https://tracknarino-backend.onrender.com/
  ```

---

## ✅ Checklist Final

- [ ] `isDevelopment = false`
- [ ] URL de Render actualizada
- [ ] Archivo guardado
- [ ] `flutter clean && flutter pub get` ejecutado
- [ ] Probado localmente
- [ ] Build de producción generado
- [ ] Verificado que conecta al backend real

---

¡Listo! Tu frontend ahora está configurado para producción 🚀
