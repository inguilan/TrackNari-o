import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';

class ApiService {
  static final FlutterSecureStorage _storage = FlutterSecureStorage();
  
  // Método para obtener el token de autenticación
  static Future<String?> _getToken() async {
    return await _storage.read(key: 'auth_token');
  }

  // Headers comunes para las peticiones autenticadas
  static Future<Map<String, String>> _getAuthHeaders() async {
    final token = await _getToken();
    if (token == null || token.isEmpty) {
      throw Exception('No hay token de autenticación disponible');
    }
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // Headers para peticiones sin autenticación
  static Map<String, String> _getHeaders() {
    return {
      'Content-Type': 'application/json',
    };
  }

  // Método para realizar peticiones GET
  static Future<dynamic> get(String endpoint) async {
    try {
      final headers = await _getAuthHeaders();
      if (kDebugMode) {
        print('GET request: $endpoint');
      }
      
      final response = await http.get(
        Uri.parse(endpoint),
        headers: headers,
      );
      
      return _processResponse(response, endpoint: endpoint);
    } catch (e) {
      throw Exception('Error en la petición GET a $endpoint: $e');
    }
  }

  // Método para realizar peticiones POST
  static Future<dynamic> post(String endpoint, Map<String, dynamic> data) async {
    try {
      final headers = await _getAuthHeaders();
      if (kDebugMode) {
        print('POST request: $endpoint');
        print('Data: ${jsonEncode(data)}');
      }
      
      final response = await http.post(
        Uri.parse(endpoint),
        body: jsonEncode(data),
        headers: headers,
      );
      
      return _processResponse(response, endpoint: endpoint);
    } catch (e) {
      throw Exception('Error en la petición POST a $endpoint: $e');
    }
  }

  // Método para realizar peticiones POST sin autenticación (login/registro)
  static Future<dynamic> postUnauth(String endpoint, Map<String, dynamic> data) async {
    try {
      if (kDebugMode) {
        print('---------- INICIO PETICIÓN ----------');
        print('POST no autenticado a: $endpoint');
        print('Headers: ${_getHeaders()}');
        print('Datos enviados:');
        print(const JsonEncoder.withIndent('  ').convert(data));
      }
      
      final response = await http.post(
        Uri.parse(endpoint),
        body: jsonEncode(data),
        headers: _getHeaders(),
      );
      
      if (kDebugMode) {
        print('Respuesta recibida. Status: ${response.statusCode}');
        try {
          print('Cuerpo de respuesta:');
          print(const JsonEncoder.withIndent('  ').convert(jsonDecode(response.body)));
        } catch (e) {
          print('No se pudo decodificar respuesta como JSON: ${response.body}');
        }
        print('---------- FIN PETICIÓN ----------');
      }
      
      return _processResponse(response, endpoint: endpoint);
    } catch (e) {
      if (kDebugMode) {
        print('ERROR en petición POST: $e');
        print('---------- FIN PETICIÓN CON ERROR ----------');
      }
      throw Exception('Error en la petición POST no autenticada a $endpoint: $e');
    }
  }

  // Método para realizar peticiones PUT
  static Future<dynamic> put(String endpoint, Map<String, dynamic> data) async {
    try {
      final headers = await _getAuthHeaders();
      if (kDebugMode) {
        print('PUT request: $endpoint');
        print('Data: ${jsonEncode(data)}');
      }
      
      final response = await http.put(
        Uri.parse(endpoint),
        body: jsonEncode(data),
        headers: headers,
      );
      
      return _processResponse(response, endpoint: endpoint);
    } catch (e) {
      throw Exception('Error en la petición PUT a $endpoint: $e');
    }
  }

  // Método para realizar peticiones DELETE
  static Future<dynamic> delete(String endpoint) async {
    try {
      final headers = await _getAuthHeaders();
      if (kDebugMode) {
        print('DELETE request: $endpoint');
      }
      
      final response = await http.delete(
        Uri.parse(endpoint),
        headers: headers,
      );
      
      return _processResponse(response, endpoint: endpoint);
    } catch (e) {
      throw Exception('Error en la petición DELETE a $endpoint: $e');
    }
  }

  // Método para procesar las respuestas del servidor
  static dynamic _processResponse(http.Response response, {required String endpoint}) {
    if (kDebugMode) {
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');
    }
    
    if (response.statusCode >= 200 && response.statusCode < 300) {
      try {
        return jsonDecode(response.body);
      } catch (e) {
        throw Exception('Error al decodificar respuesta JSON: $e');
      }
    } else {
      String errorMessage = 'Error ${response.statusCode}';
      
      try {
        final errorResponse = jsonDecode(response.body);
        if (errorResponse['message'] != null) {
          errorMessage = errorResponse['message'];
        } else if (errorResponse['error'] != null) {
          errorMessage = errorResponse['error'];
        }
      } catch (e) {
        // Si no se puede parsear el error, usar el mensaje genérico
      }
      
      throw Exception('$errorMessage (Endpoint: $endpoint)');
    }
  }
} 