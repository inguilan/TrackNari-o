import 'package:flutter/foundation.dart';

import '../config/api_config.dart';
import '../models/oportunidad_model.dart';
import 'api_service.dart';

class OportunidadService {
  // Obtener listado de oportunidades disponibles
  static Future<List<Oportunidad>> obtenerOportunidadesDisponibles() async {
    try {
      if (kDebugMode) {
        print(
          'Obteniendo oportunidades desde: ${ApiConfig.oportunidades}/disponibles',
        );
      }

      final response = await ApiService.get(
        '${ApiConfig.oportunidades}/disponibles',
      );

      if (kDebugMode) {
        print('Respuesta del servidor: $response');
      }

      if (response == null) {
        if (kDebugMode) {
          print('Respuesta nula del servidor');
        }
        return [];
      }

      // El backend puede devolver {oportunidades: [...]} o directamente [...]
      List<dynamic> oportunidadesData;
      if (response is Map && response.containsKey('oportunidades')) {
        oportunidadesData = response['oportunidades'] as List;
      } else if (response is List) {
        oportunidadesData = response;
      } else {
        if (kDebugMode) {
          print('Formato de respuesta inesperado: ${response.runtimeType}');
        }
        return [];
      }

      return oportunidadesData
          .map((data) => Oportunidad.fromJson(data))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error al obtener oportunidades: $e');
      }
      rethrow;
    }
  }

  // Obtener detalles de una oportunidad específica
  static Future<Oportunidad?> obtenerDetalleOportunidad(String id) async {
    try {
      if (kDebugMode) {
        print('Obteniendo detalle de oportunidad: $id');
      }

      final response = await ApiService.get('${ApiConfig.oportunidades}/$id');

      if (response == null) {
        return null;
      }

      // El backend puede devolver {oportunidad: {...}} o directamente {...}
      Map<String, dynamic> oportunidadData;
      if (response is Map && response.containsKey('oportunidad')) {
        oportunidadData = Map<String, dynamic>.from(response['oportunidad']);
      } else if (response is Map) {
        oportunidadData = Map<String, dynamic>.from(response);
      } else {
        return null;
      }

      return Oportunidad.fromJson(oportunidadData);
    } catch (e) {
      if (kDebugMode) {
        print('Error al obtener detalle de oportunidad: $e');
      }
      return null;
    }
  }

  // Aplicar/Aceptar una oportunidad (camioneros)
  static Future<Map<String, dynamic>> aplicarOportunidad(
    String oportunidadId,
  ) async {
    try {
      if (kDebugMode) {
        print('Aceptando oportunidad: $oportunidadId');
      }

      // El backend usa PUT /:id/aceptar
      final response = await ApiService.put(
        '${ApiConfig.oportunidades}/$oportunidadId/aceptar',
        {},
      );

      if (kDebugMode) {
        print('Respuesta al aceptar oportunidad: $response');
      }

      return response ??
          {'success': false, 'message': 'Respuesta vacía del servidor'};
    } catch (e) {
      if (kDebugMode) {
        print('Error al aceptar oportunidad: $e');
      }
      rethrow;
    }
  }

  // Crear una nueva oportunidad (solo contratistas)
  static Future<Oportunidad?> crearOportunidad({
    required String titulo,
    String? descripcion,
    required String origen,
    required String destino,
    required DateTime fecha,
    required double precio,
  }) async {
    try {
      final data = {
        'titulo': titulo,
        'descripcion': descripcion,
        'origen': origen,
        'destino': destino,
        'fecha': fecha.toIso8601String(),
        'precio': precio,
      };

      if (kDebugMode) {
        print('Creando oportunidad: $data');
      }

      final response = await ApiService.post(
        '${ApiConfig.oportunidades}/crear',
        data,
      );

      if (kDebugMode) {
        print('Respuesta al crear: $response');
      }

      if (response == null) return null;

      // El backend devuelve {oportunidad: {...}}
      if (response is Map && response.containsKey('oportunidad')) {
        return Oportunidad.fromJson(
          Map<String, dynamic>.from(response['oportunidad']),
        );
      } else if (response is Map) {
        return Oportunidad.fromJson(Map<String, dynamic>.from(response));
      }

      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Error al crear oportunidad: $e');
      }
      rethrow;
    }
  }

  // Crear una nueva oportunidad con todos los campos (solo contratistas)
  static Future<Oportunidad?> crearOportunidadCompleta(
    Map<String, dynamic> data,
  ) async {
    try {
      if (kDebugMode) {
        print('Intentando crear oportunidad completa con datos: $data');
      }

      final response = await ApiService.post(
        '${ApiConfig.oportunidades}/crear',
        data,
      );

      if (kDebugMode) {
        print('Respuesta del servidor al crear oportunidad: $response');
      }

      if (response == null) return null;

      // El backend devuelve {oportunidad: {...}}
      if (response is Map && response.containsKey('oportunidad')) {
        return Oportunidad.fromJson(
          Map<String, dynamic>.from(response['oportunidad']),
        );
      } else if (response is Map) {
        return Oportunidad.fromJson(Map<String, dynamic>.from(response));
      }

      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Error detallado al crear oportunidad completa: $e');
      }
      rethrow;
    }
  }

  // Asignar un camionero a una oportunidad (solo contratistas)
  static Future<bool> asignarCamionero({
    required String oportunidadId,
    required String camioneroId,
  }) async {
    try {
      final data = {'camioneroId': camioneroId};

      await ApiService.post(
        '${ApiConfig.oportunidades}/asignar/$oportunidadId',
        data,
      );
      return true;
    } catch (e) {
      print('Error al asignar camionero: $e');
      return false;
    }
  }

  // Finalizar una carga (solo contratistas)
  static Future<bool> finalizarCarga(String oportunidadId) async {
    try {
      await ApiService.post(
        '${ApiConfig.oportunidades}/finalizar/$oportunidadId',
        {},
      );
      return true;
    } catch (e) {
      print('Error al finalizar carga: $e');
      return false;
    }
  }

  /// Aceptar una oportunidad (nuevo método con validaciones)
  static Future<Oportunidad> aceptarOportunidad(String oportunidadId) async {
    try {
      final response = await ApiService.put(
        '${ApiConfig.oportunidades}/$oportunidadId/aceptar',
        {},
      );

      return Oportunidad.fromJson(response['oportunidad']);
    } catch (e) {
      print('Error al aceptar oportunidad: $e');
      rethrow;
    }
  }

  /// Obtener viaje activo del camionero
  static Future<Oportunidad?> obtenerViajeActivo() async {
    try {
      final response = await ApiService.get(
        '${ApiConfig.oportunidades}/viaje-activo',
      );

      if (response['viajeActivo'] == null) {
        return null;
      }

      return Oportunidad.fromJson(response['viajeActivo']);
    } catch (e) {
      print('Error al obtener viaje activo: $e');
      return null;
    }
  }

  /// Iniciar viaje
  static Future<Oportunidad> iniciarViaje(String oportunidadId) async {
    try {
      final response = await ApiService.put(
        '${ApiConfig.oportunidades}/$oportunidadId/iniciar',
        {},
      );

      return Oportunidad.fromJson(response['oportunidad']);
    } catch (e) {
      print('Error al iniciar viaje: $e');
      rethrow;
    }
  }

  /// Finalizar viaje
  static Future<Oportunidad> finalizarViaje(String oportunidadId) async {
    try {
      final response = await ApiService.put(
        '${ApiConfig.oportunidades}/$oportunidadId/finalizar',
        {},
      );

      return Oportunidad.fromJson(response['oportunidad']);
    } catch (e) {
      print('Error al finalizar viaje: $e');
      rethrow;
    }
  }

  /// Cancelar viaje (camionero se sale del viaje)
  static Future<Oportunidad> cancelarViaje(String oportunidadId) async {
    try {
      final response = await ApiService.put(
        '${ApiConfig.oportunidades}/$oportunidadId/cancelar',
        {},
      );

      return Oportunidad.fromJson(response['oportunidad']);
    } catch (e) {
      print('Error al cancelar viaje: $e');
      rethrow;
    }
  }
}
