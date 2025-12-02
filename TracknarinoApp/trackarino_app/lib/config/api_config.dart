import 'dart:io';
import 'package:flutter/foundation.dart';

class ApiConfig {
  static bool isDevelopment = false; // ✅ Cambiar a false para usar producción
  
  // Determinar la URL base correcta según la plataforma
  static String get _baseUrl {
    if (isDevelopment) {
      if (kIsWeb) {
        return 'http://localhost:4000/api';
      } else if (Platform.isAndroid) {
        return 'http://10.0.2.2:4000/api'; // Para emulador Android
      } else {
        return 'http://localhost:4000/api'; // Para iOS o escritorio
      }
    } else {
      // URL de producción - Render ✅ Corregida
      return 'https://tracknari-o-1.onrender.com/api';
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
  
  // Token de API de Google Maps
  static const String googleMapsApiKey = 'YOUR_GOOGLE_MAPS_API_KEY'; // Reemplazar en producción
  
  // Parámetros de autenticación
  static const String tokenKey = 'auth_token';
} 