import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import '../models/user_model.dart';
import '../config/api_config.dart';
import '../api_service.dart';

class AuthService extends ChangeNotifier {
  User? _currentUser;
  bool _isAuthenticated = false;
  final FlutterSecureStorage _storage = FlutterSecureStorage();
  static final FlutterSecureStorage _staticStorage = FlutterSecureStorage();

  // Getters
  User? get currentUser => _currentUser;
  bool get isAuthenticated => _isAuthenticated;
  
  // Método estático para obtener el token
  static Future<String?> getToken() async {
    final token = await _staticStorage.read(key: ApiConfig.tokenKey);
    if (token == null && kDebugMode) {
      print('WARNING: No token found in secure storage');
    }
    return token;
  }
  
  // Inicializa el estado de autenticación al arrancar la app
  Future<void> init() async {
    try {
      final token = await _storage.read(key: ApiConfig.tokenKey);
      final userString = await _storage.read(key: 'user_data');
      
      if (token != null && userString != null) {
        try {
          if (kDebugMode) {
            print('Recuperando sesión de usuario');
          }
          
          final userData = jsonDecode(userString);
          _currentUser = User.fromJson(userData);
          _isAuthenticated = true;
          
          if (kDebugMode) {
            print('Sesión recuperada para: ${_currentUser?.nombre}');
          }
        } catch (e) {
          if (kDebugMode) {
            print('Error al decodificar datos del usuario: $e');
          }
          await logout(); // Si hay error en los datos guardados, cierra sesión
        }
      } else {
        if (kDebugMode) {
          print('No hay sesión guardada: token=${token != null}, userData=${userString != null}');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error al inicializar autenticación: $e');
      }
    }
    
    notifyListeners();
  }

  // Iniciar sesión
  Future<User> login(String correo, String contrasena) async {
    try {
      final data = {
        'correo': correo,
        'contraseña': contrasena,
      };
      
      if (kDebugMode) {
        print('Intentando iniciar sesión para: $correo');
      }
      
      final response = await ApiService.postUnauth(ApiConfig.login, data);
      
      if (response['token'] == null || response['usuario'] == null) {
        throw Exception('Respuesta del servidor incorrecta');
      }
      
      // Guardar token y datos de usuario
      await _storage.write(key: ApiConfig.tokenKey, value: response['token']);
      _currentUser = User.fromJson(response['usuario']);
      _isAuthenticated = true;
      
      // Guardar los datos del usuario como JSON
      await _storage.write(key: 'user_data', value: jsonEncode(response['usuario']));
      
      if (kDebugMode) {
        print('Sesión iniciada con éxito para: ${_currentUser?.nombre}');
        print('Token guardado: ${response['token']}');
      }
      
      notifyListeners();
      return _currentUser!;
    } catch (e) {
      if (kDebugMode) {
        print('Error al iniciar sesión: $e');
      }
      throw Exception('Error al iniciar sesión: $e');
    }
  }

  // Registrar nuevo usuario
  Future<User> register(Map<String, dynamic> userData) async {
    try {
      final response = await ApiService.postUnauth(ApiConfig.register, userData);
      
      if (response['token'] == null || response['usuario'] == null) {
        throw Exception('Respuesta del servidor incorrecta');
      }
      
      // Guardar token y datos de usuario
      await _storage.write(key: ApiConfig.tokenKey, value: response['token']);
      _currentUser = User.fromJson(response['usuario']);
      _isAuthenticated = true;
      
      // Guardar los datos del usuario como JSON
      await _storage.write(key: 'user_data', value: jsonEncode(response['usuario']));
      
      if (kDebugMode) {
        print('Usuario registrado con éxito: ${_currentUser?.nombre}');
        print('Token guardado: ${response['token']}');
      }
      
      notifyListeners();
      return _currentUser!;
    } catch (e) {
      if (kDebugMode) {
        print('Error al registrar usuario: $e');
      }
      throw Exception('Error al registrar usuario: $e');
    }
  }

  // Cerrar sesión
  Future<void> logout() async {
    try {
      await _storage.delete(key: ApiConfig.tokenKey);
      await _storage.delete(key: 'user_data');
      _currentUser = null;
      _isAuthenticated = false;
      
      if (kDebugMode) {
        print('Sesión cerrada con éxito');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error al cerrar sesión: $e');
      }
    }
    
    notifyListeners();
  }

  // Verificar si el token sigue siendo válido
  Future<bool> verificarToken() async {
    try {
      final token = await getToken();
      
      if (token == null) {
        if (kDebugMode) {
          print('No hay token para verificar');
        }
        return false;
      }
      
      if (kDebugMode) {
        print('Verificando validez del token');
      }
      
      // Intentamos hacer una petición a un endpoint protegido
      final response = await ApiService.get('${ApiConfig.users}/perfil');
      
      // Si llegamos aquí, el token es válido
      if (response['usuario'] != null) {
        _currentUser = User.fromJson(response['usuario']);
        _isAuthenticated = true;
        
        // Actualizar datos guardados para mantenerlos frescos
        await _storage.write(key: 'user_data', value: jsonEncode(response['usuario']));
        
        if (kDebugMode) {
          print('Token verificado correctamente para: ${_currentUser?.nombre}');
        }
        
        notifyListeners();
        return true;
      }
      
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('Error al verificar token: $e');
      }
      
      // Si hay error, probablemente el token expiró
      await logout();
      return false;
    }
  }

  // Actualizar método de pago
  Future<User> actualizarMetodoPago(String metodoPago) async {
    try {
      final data = {
        'metodoPago': metodoPago,
      };
      
      final response = await ApiService.put('${ApiConfig.baseUrl}/auth/actualizar-pago', data);
      
      if (response['usuario'] == null) {
        throw Exception('Respuesta del servidor incorrecta');
      }
      
      _currentUser = User.fromJson(response['usuario']);
      
      // Actualizar datos guardados
      await _storage.write(key: 'user_data', value: jsonEncode(response['usuario']));
      
      notifyListeners();
      return _currentUser!;
    } catch (e) {
      if (kDebugMode) {
        print('Error al actualizar método de pago: $e');
      }
      throw Exception('Error al actualizar método de pago: $e');
    }
  }

  // Actualizar token del dispositivo para notificaciones push
  Future<void> actualizarDeviceToken(String token) async {
    try {
      if (_currentUser != null) {
        final data = {
          'deviceToken': token,
        };
        
        await ApiService.put('${ApiConfig.users}/${_currentUser!.id}', data);
        
        if (kDebugMode) {
          print('Token de dispositivo actualizado con éxito');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error al actualizar device token: $e');
      }
    }
  }

  // Obtener datos del perfil del camionero
  Future<User?> obtenerPerfilCamionero() async {
    try {
      final response = await ApiService.get('${ApiConfig.users}/perfil');
      final usuario = User.fromJson(response['usuario']);
      _currentUser = usuario;
      
      // Actualizar datos guardados
      await _storage.write(key: 'user_data', value: jsonEncode(response['usuario']));
      
      notifyListeners();
      return usuario;
    } catch (e) {
      if (kDebugMode) {
        print('Error al obtener perfil del camionero: $e');
      }
      return null;
    }
  }

  // Guardar estado disponible
  Future<void> guardarEstadoDisponible(bool disponible) async {
    try {
      await _storage.write(key: 'estado_disponible', value: disponible.toString());
      if (kDebugMode) {
        print('Estado disponible guardado: $disponible');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error al guardar estado disponible: $e');
      }
    }
  }

  // Recuperar estado disponible
  Future<bool> obtenerEstadoDisponible() async {
    try {
      final estadoString = await _storage.read(key: 'estado_disponible');
      if (estadoString == null) return false;
      return estadoString == 'true';
    } catch (e) {
      if (kDebugMode) {
        print('Error al obtener estado disponible: $e');
      }
      return false;
    }
  }
} 