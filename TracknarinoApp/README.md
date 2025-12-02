# 🚛 TracknariñoApp

> Sistema de gestión y seguimiento logístico para el transporte de carga en el departamento de Nariño, Colombia.

[![Node.js](https://img.shields.io/badge/Node.js-18+-green.svg)](https://nodejs.org/)
[![Flutter](https://img.shields.io/badge/Flutter-3.0+-blue.svg)](https://flutter.dev/)
[![MongoDB](https://img.shields.io/badge/MongoDB-5.0+-brightgreen.svg)](https://www.mongodb.com/)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

---

## 📋 Descripción

**Tracknariño** es una plataforma integral diseñada para optimizar la eficiencia y seguridad del transporte de carga en el departamento de Nariño. La aplicación conecta contratistas con camioneros, facilitando:

- 📦 Gestión de oportunidades logísticas
- 🗺️ Seguimiento en tiempo real con GPS
- 🚨 Sistema de alertas de seguridad
- 💼 Panel administrativo para contratistas
- 📱 Aplicación móvil multiplataforma

---

## 🏗️ Arquitectura

```
┌─────────────────┐      ┌──────────────────┐      ┌─────────────────┐
│  Flutter App    │ ───► │  Backend API     │ ───► │  MongoDB Atlas  │
│  (Mobile/Web)   │      │  (Node.js)       │      │  (Cloud DB)     │
└─────────────────┘      └──────────────────┘      └─────────────────┘
        │                         │
        │                         │
        ▼                         ▼
┌─────────────────┐      ┌──────────────────┐
│  Firebase FCM   │      │  OpenRouteService│
│  (Push Notif.)  │      │  (Routing)       │
└─────────────────┘      └──────────────────┘
```

---

## ✨ Características Principales

### 👥 Para Contratistas
- ✅ Crear y publicar oportunidades de transporte
- ✅ Gestionar cargas en tiempo real
- ✅ Ver ubicación de camioneros asignados
- ✅ Sistema de calificaciones
- ✅ Historial de servicios

### 🚚 Para Camioneros
- ✅ Ver oportunidades disponibles
- ✅ Aceptar cargas según disponibilidad
- ✅ Navegación GPS integrada
- ✅ Reporte de incidentes y alertas
- ✅ Historial de viajes

### 🔐 Sistema General
- ✅ Autenticación JWT segura
- ✅ Roles diferenciados (Contratista/Camionero)
- ✅ Notificaciones push en tiempo real
- ✅ Sistema de alertas de seguridad
- ✅ API RESTful completa

---

## 🚀 Despliegue en la Nube

La aplicación está desplegada en:

| Componente | Servicio | URL |
|------------|----------|-----|
| **Backend API** | Render | `https://tracknarino-backend.onrender.com` |
| **Base de Datos** | MongoDB Atlas | (Cloud) |
| **Frontend Web** | Vercel | `https://tracknarino.vercel.app` |
| **APK Android** | Local | `build/app/outputs/` |

### 📚 Guías de Despliegue

- 📖 [**Guía Completa de Despliegue Cloud**](GUIA_DESPLIEGUE_CLOUD.md) - Paso a paso detallado
- 🚀 [**Despliegue Rápido**](DESPLIEGUE_RAPIDO.md) - Versión resumida
- ✅ [**Checklist de Despliegue**](CHECKLIST_DESPLIEGUE.md) - Verificación completa
- 📝 [**Actualizar API Config**](ACTUALIZAR_API_CONFIG.md) - Configuración de producción
- 📊 [**Resumen de Despliegue**](RESUMEN_DESPLIEGUE.md) - Vista general

---

## 💻 Desarrollo Local

### 📋 Requisitos Previos

- **Node.js** v18+ ([Descargar](https://nodejs.org/))
- **MongoDB** v5.0+ ([Descargar](https://www.mongodb.com/try/download/community))
- **Flutter SDK** v3.0+ ([Descargar](https://flutter.dev/docs/get-started/install))
- **Git** ([Descargar](https://git-scm.com/))

### 🔧 Instalación

#### 1. Clonar el Repositorio
```bash
git clone https://github.com/ChrispinSantacruz/TracknarinoApp.git
cd TracknarinoApp
```

#### 2. Configurar Backend

```bash
cd Backend

# Instalar dependencias
npm install

# Copiar archivo de configuración
copy .env.example .env

# Editar .env con tus credenciales
# MONGO_URI=mongodb://localhost:27017/trackarino
# JWT_SECRET=tu_clave_secreta

# Iniciar MongoDB (Windows)
net start MongoDB

# Crear datos de prueba
node scripts/crear_oportunidades_prueba.js

# Iniciar servidor
npm start
```

El backend estará en: `http://localhost:4000`

#### 3. Configurar Frontend

```bash
cd trackarino_app

# Instalar dependencias
flutter pub get

# Verificar instalación
flutter doctor

# Ejecutar app
flutter run -d chrome        # Para web
flutter run -d android       # Para Android
flutter run -d windows       # Para Windows
```

---

## 🧪 Probar con Datos Reales

### Opción 1: Usar Script de Datos

```bash
cd Backend
node scripts/crear_oportunidades_prueba.js
```

Esto crea:
- 1 usuario contratista (`contratista@trackarino.com` / `123456`)
- 6 oportunidades de transporte realistas

### Opción 2: Crear Manualmente

1. Abrir app
2. Registrar usuario contratista
3. Crear oportunidad desde la app
4. Registrar usuario camionero
5. Aceptar oportunidad

📖 [**Guía Completa de Datos Reales**](GUIA_DATOS_REALES.md)

---

## 📁 Estructura del Proyecto

```
TracknarinoApp/
├── Backend/                          # API REST Node.js + Express
│   ├── controllers/                  # Lógica de negocio
│   ├── models/                       # Modelos MongoDB
│   ├── routes/                       # Endpoints API
│   ├── scripts/                      # Utilidades
│   ├── services/                     # FCM, ORS
│   └── server.js                     # Punto de entrada
│
├── trackarino_app/                   # Aplicación Flutter
│   ├── lib/
│   │   ├── config/                   # Configuración API
│   │   ├── models/                   # Modelos de datos
│   │   ├── screens/                  # Pantallas UI
│   │   └── services/                 # Servicios API
│   └── pubspec.yaml
│
└── 📚 Documentación
    ├── GUIA_DESPLIEGUE_CLOUD.md
    ├── CHECKLIST_DESPLIEGUE.md
    └── README.md
```

---

## 🔌 API Endpoints Principales

```
POST   /api/auth/register              - Registro
POST   /api/auth/login                 - Login
GET    /api/oportunidades/disponibles  - Listar oportunidades
POST   /api/oportunidades/crear        - Crear oportunidad
PUT    /api/oportunidades/:id/aceptar  - Aceptar oportunidad
```

---

## 🚢 Despliegue en la Nube

### URLs de Producción:
- **Backend**: `https://tracknarino-backend.onrender.com`
- **Frontend Web**: `https://tracknarino.vercel.app`

### Servicios Utilizados:
- **MongoDB Atlas** - Base de datos (Free M0)
- **Render** - Backend Node.js (Free Tier)
- **Vercel** - Frontend Flutter Web (Hobby)

📖 Ver [**GUIA_DESPLIEGUE_CLOUD.md**](GUIA_DESPLIEGUE_CLOUD.md) para instrucciones completas

---

## 💻 Tecnologías

**Backend:** Node.js, Express, MongoDB, JWT, Firebase  
**Frontend:** Flutter, Dart, Provider, Google Maps  
**Cloud:** Render, Vercel, MongoDB Atlas

---

## 📊 Costos: $0/mes

Todos los servicios en plan gratuito.

---

## 🎓 Proyecto de Tesis

Este proyecto fue desarrollado como trabajo de grado para optimizar el transporte de carga en Nariño, Colombia.

**Autor:** Chrispin Santacruz  
**Universidad:** [Tu Universidad]

---

## 📚 Documentación

- [Guía de Datos Reales](GUIA_DATOS_REALES.md)
- [Guía de Despliegue Cloud](GUIA_DESPLIEGUE_CLOUD.md)
- [Checklist de Despliegue](CHECKLIST_DESPLIEGUE.md)
- [Despliegue Rápido](DESPLIEGUE_RAPIDO.md)
- [Actualizar API Config](ACTUALIZAR_API_CONFIG.md)

---

<div align="center">

**🚛 Tracknariño - Transporte inteligente para Nariño 🚛**

[![Node.js](https://img.shields.io/badge/Node.js-18+-green.svg)](https://nodejs.org/)
[![Flutter](https://img.shields.io/badge/Flutter-3.0+-blue.svg)](https://flutter.dev/)
[![MongoDB](https://img.shields.io/badge/MongoDB-Atlas-brightgreen.svg)](https://www.mongodb.com/)

Hecho con ❤️ en Colombia

</div> 