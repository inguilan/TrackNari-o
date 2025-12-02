import '../config/api_config.dart';
import '../models/alerta_model.dart';
import 'api_service.dart';
import 'package:geolocator/geolocator.dart';

class AlertaService {
  // Crear una nueva alerta de seguridad
  static Future<AlertaSeguridad?> crearAlerta({
    required String tipo,
    required Map<String, double> coords,
    String? descripcion,
    String? imagePath,
    bool compartir = true,
  }) async {
    try {
      final Map<String, dynamic> data = {
        'tipo': tipo,
        'coords': coords,
        'descripcion': descripcion,
        'compartir': compartir,
      };
      
      if (imagePath != null) {
        // En una implementación real, aquí subiríamos la imagen
        // Por ahora simulamos que se subió exitosamente
        data['imagenUrl'] = 'https://ejemplo.com/imagen.jpg';
      }
      
      final response = await ApiService.post(ApiConfig.alertas, data);
      
      // El backend responde con {mensaje: '...', alerta: {...}}
      // Necesitamos extraer solo el objeto 'alerta'
      if (response is Map<String, dynamic> && response.containsKey('alerta')) {
        return AlertaSeguridad.fromJson(response['alerta']);
      } else {
        // Si la respuesta no tiene la estructura esperada, intentar parsear directamente
        return AlertaSeguridad.fromJson(response);
      }
    } catch (e) {
      print('Error al crear alerta: $e');
      rethrow;
    }
  }

  // Obtener alertas cercanas a una posición
  static Future<List<AlertaSeguridad>> obtenerAlertasCercanas(Position position) async {
    try {
      final data = {
        'lat': position.latitude,
        'lng': position.longitude,
        'radio': 50000, // 50 km de radio para buscar alertas
      };
      
      final response = await ApiService.post(
        '${ApiConfig.alertas}/cercanas', 
        data,
      );
      
      // La respuesta es directamente un array de alertas
      return (response as List)
          .map((data) => AlertaSeguridad.fromJson(data))
          .toList();
    } catch (e) {
      print('Error al obtener alertas cercanas: $e');
      rethrow;
    }
  }

  // Obtener todas las alertas recientes (últimas 24 horas)
  static Future<List<AlertaSeguridad>> obtenerAlertasRecientes() async {
    try {
      final response = await ApiService.get('${ApiConfig.alertas}/recientes');
      return (response as List)
          .map((data) => AlertaSeguridad.fromJson(data))
          .toList();
    } catch (e) {
      print('Error al obtener alertas recientes: $e');
      return [];
    }
  }

  // Confirmar una alerta existente
  static Future<bool> confirmarAlerta(String alertaId) async {
    try {
      final response = await ApiService.post(
        '${ApiConfig.alertas}/confirmar/$alertaId',
        {},
      );
      
      return response['success'] == true;
    } catch (e) {
      print('Error al confirmar alerta: $e');
      return true; // Simulamos éxito en desarrollo
    }
  }
  
  // Compartir una alerta existente
  static Future<bool> compartirAlerta(String alertaId) async {
    try {
      final response = await ApiService.post(
        '${ApiConfig.alertas}/compartir/$alertaId',
        {},
      );
      
      return response['success'] == true;
    } catch (e) {
      print('Error al compartir alerta: $e');
      return true; // Simulamos éxito en desarrollo
    }
  }

  // Método auxiliar para generación de datos simulados durante desarrollo
  static List<AlertaSeguridad> _generarAlertasSimuladas(Position position) {
    // Crear algunas alertas ficticias alrededor de la posición actual
    return [
      AlertaSeguridad(
        id: '1',
        tipo: 'trancon',
        descripcion: 'Tráfico intenso por obras en la carretera. Se recomienda tomar ruta alterna.',
        usuario: 'usuario1',
        coords: {
          'lat': position.latitude + 0.01,
          'lng': position.longitude - 0.01,
        },
        timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
      ),
      AlertaSeguridad(
        id: '2',
        tipo: 'obstaculo',
        descripcion: 'Árbol caído en la vía. Precaución al pasar.',
        usuario: 'usuario2',
        coords: {
          'lat': position.latitude - 0.02,
          'lng': position.longitude + 0.03,
        },
        timestamp: DateTime.now().subtract(const Duration(hours: 1)),
      ),
      AlertaSeguridad(
        id: '3',
        tipo: 'sospecha',
        descripcion: 'Vehículo sospechoso estacionado en la curva.',
        usuario: 'usuario3',
        coords: {
          'lat': position.latitude + 0.03,
          'lng': position.longitude + 0.02,
        },
        timestamp: DateTime.now().subtract(const Duration(minutes: 45)),
      ),
      AlertaSeguridad(
        id: '4',
        tipo: 'policia',
        descripcion: 'Control policial verificando documentos y realizando pruebas de alcoholemia.',
        usuario: 'usuario4',
        coords: {
          'lat': position.latitude - 0.01,
          'lng': position.longitude - 0.02,
        },
        timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
      ),
    ];
  }
  
  // Simular la creación de una alerta durante desarrollo
  static AlertaSeguridad _simularCreacionAlerta(
      String tipo, Map<String, double> coords, String? descripcion) {
    return AlertaSeguridad(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      tipo: tipo,
      descripcion: descripcion,
      usuario: 'usuario_actual',
      coords: coords,
      timestamp: DateTime.now(),
    );
  }
} 