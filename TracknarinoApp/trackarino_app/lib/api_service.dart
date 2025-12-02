import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'config/api_config.dart';
import 'services/auth_service.dart'; // Para manejo de tokens

class ApiService {
  // Headers comunes para todas las peticiones
  static Map<String, String> _getHeaders({bool needsAuth = true}) {
    Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    
    return headers;
  }
  
  // Agregar token de autorización a los headers
  static Future<Map<String, String>> _getAuthHeaders({bool needsAuth = true}) async {
    Map<String, String> headers = _getHeaders(needsAuth: needsAuth);
    
    // Agregar token de autenticación si es necesario
    if (needsAuth) {
      final token = await AuthService.getToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
        if (kDebugMode) {
          print('ADDING AUTH TOKEN: Bearer $token');
        }
      } else {
        if (kDebugMode) {
          print('WARNING: No token available for authenticated request');
        }
      }
    }
    
    return headers;
  }
  
  // Método GET
  static Future<dynamic> get(String url, {bool needsAuth = true}) async {
    try {
      if (kDebugMode) {
        print('GET REQUEST: $url');
      }
      
      final uri = Uri.parse(url);
      final headers = await _getAuthHeaders(needsAuth: needsAuth);
      if (kDebugMode) {
        print('Headers: $headers');
      }
      
      final response = await http.get(
        uri,
        headers: headers,
      ).timeout(Duration(seconds: ApiConfig.timeoutSeconds));
      
      return _processResponse(response);
    } catch (e) {
      if (kDebugMode) {
        print('GET ERROR: $e');
      }
      throw _handleError(e);
    }
  }
  
  // Método POST
  static Future<dynamic> post(String url, dynamic data, {bool needsAuth = true}) async {
    try {
      if (kDebugMode) {
        print('POST REQUEST: $url');
        print('POST DATA: $data');
      }
      
      final uri = Uri.parse(url);
      final headers = await _getAuthHeaders(needsAuth: needsAuth);
      if (kDebugMode) {
        print('Headers: $headers');
      }
      
      final response = await http.post(
        uri,
        headers: headers,
        body: jsonEncode(data),
      ).timeout(Duration(seconds: ApiConfig.timeoutSeconds));
      
      return _processResponse(response);
    } catch (e) {
      if (kDebugMode) {
        print('POST ERROR: $e');
      }
      throw _handleError(e);
    }
  }
  
  // Método POST sin autenticación (para login/registro)
  static Future<dynamic> postUnauth(String url, dynamic data) async {
    return post(url, data, needsAuth: false);
  }
  
  // Método PUT
  static Future<dynamic> put(String url, dynamic data, {bool needsAuth = true}) async {
    try {
      if (kDebugMode) {
        print('PUT REQUEST: $url');
        print('PUT DATA: $data');
      }
      
      final uri = Uri.parse(url);
      final headers = await _getAuthHeaders(needsAuth: needsAuth);
      if (kDebugMode) {
        print('Headers: $headers');
      }
      
      final response = await http.put(
        uri,
        headers: headers,
        body: jsonEncode(data),
      ).timeout(Duration(seconds: ApiConfig.timeoutSeconds));
      
      return _processResponse(response);
    } catch (e) {
      if (kDebugMode) {
        print('PUT ERROR: $e');
      }
      throw _handleError(e);
    }
  }
  
  // Método DELETE
  static Future<dynamic> delete(String url, {bool needsAuth = true}) async {
    try {
      if (kDebugMode) {
        print('DELETE REQUEST: $url');
      }
      
      final uri = Uri.parse(url);
      final headers = await _getAuthHeaders(needsAuth: needsAuth);
      if (kDebugMode) {
        print('Headers: $headers');
      }
      
      final response = await http.delete(
        uri,
        headers: headers,
      ).timeout(Duration(seconds: ApiConfig.timeoutSeconds));
      
      return _processResponse(response);
    } catch (e) {
      if (kDebugMode) {
        print('DELETE ERROR: $e');
      }
      throw _handleError(e);
    }
  }
  
  // Procesar respuesta HTTP y manejar códigos de estado
  static dynamic _processResponse(http.Response response) {
    if (kDebugMode) {
      print('RESPONSE CODE: ${response.statusCode}');
      print('RESPONSE BODY: ${response.body}');
    }
    
    switch (response.statusCode) {
      case 200:
      case 201:
        if (response.body.isEmpty) return {};
        try {
          return json.decode(response.body);
        } catch (e) {
          if (kDebugMode) {
            print('Error decodificando respuesta JSON: $e');
          }
          throw 'Error en el formato de la respuesta del servidor';
        }
      case 204:
        return {};
      case 400:
        try {
          final decodedBody = json.decode(response.body);
          throw decodedBody['mensaje'] ?? 'Solicitud incorrecta. Por favor revisa los datos enviados.';
        } catch (e) {
          throw 'Solicitud incorrecta. Por favor revisa los datos enviados.';
        }
      case 401:
        throw 'No autorizado. Por favor inicia sesión de nuevo.';
      case 403:
        try {
          final decodedBody = json.decode(response.body);
          throw decodedBody['mensaje'] ?? 'Acceso denegado. No tienes permiso para esta acción.';
        } catch (e) {
          throw 'Acceso denegado. No tienes permiso para esta acción.';
        }
      case 404:
        throw 'La información solicitada no se encontró.';
      case 422:
        try {
          final decodedBody = json.decode(response.body);
          if (decodedBody['message'] != null) {
            throw decodedBody['message'];
          }
          throw 'Error de validación en los datos.';
        } catch (e) {
          throw 'Error de validación en los datos.';
        }
      case 500:
      case 502:
      default:
        try {
          final decodedBody = json.decode(response.body);
          throw decodedBody['mensaje'] ?? 'Error en el servidor. Por favor intenta más tarde.';
        } catch (e) {
          throw 'Error en el servidor. Por favor intenta más tarde.';
        }
    }
  }
  
  // Manejar errores comunes
  static String _handleError(dynamic error) {
    if (error is http.ClientException) {
      return 'Error de conexión. Revisa tu conexión a internet.';
    }
    
    if (error is FormatException) {
      return 'Error en el formato de los datos.';
    }
    
    if (error is TimeoutException) {
      return 'Tiempo de espera agotado. Intenta de nuevo más tarde.';
    }
    
    if (error is String) {
      return error;
    }
    
    return 'Se produjo un error inesperado.';
  }
} 