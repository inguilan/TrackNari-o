import 'package:latlong2/latlong.dart';
import '../config/api_config.dart';
import 'api_service.dart';
import 'dart:math' as math;

class ORSService {
  /// Obtiene la ruta entre dos puntos usando OSRM con reintentos
  static Future<Map<String, dynamic>> obtenerRuta(LatLng origen, LatLng destino, {int intentos = 0}) async {
    const maxIntentos = 2; // Máximo 2 reintentos
    
    try {
      print('🗺️ Obteniendo ruta: $origen → $destino ${intentos > 0 ? "(intento ${intentos + 1})" : ""}');
      
      final data = {
        'origen': [origen.longitude, origen.latitude],  // OSRM usa [lng, lat]
        'destino': [destino.longitude, destino.latitude],
      };

      print('📤 Enviando al backend: $data');

      // Usar autenticación para el endpoint ORS
      final response = await ApiService.post('${ApiConfig.baseUrl}/ors/ruta', data);
      
      print('📥 Respuesta del backend recibida');
      print('   - Respuesta completa: $response');
      
      // Parsear la respuesta
      if (response['coordinates'] != null) {
        final List<LatLng> routePoints = [];
        
        for (var coord in response['coordinates']) {
          if (coord is List && coord.length >= 2) {
            // OSRM devuelve [lng, lat], convertir a LatLng
            routePoints.add(LatLng(coord[1].toDouble(), coord[0].toDouble()));
          }
        }

        // Extraer distancia y duración (backend puede devolver con nombres diferentes)
        final distanciaVal = response['distancia'] ?? response['distance'];
        final duracionVal = response['duracion'] ?? response['duration'];
        
        final distancia = distanciaVal is String 
            ? double.parse(distanciaVal) 
            : (distanciaVal as num).toDouble();
        
        final duracion = duracionVal is String
            ? int.parse(duracionVal)
            : (duracionVal as int);

        print('✅ Ruta procesada: ${routePoints.length} puntos');
        print('   - Distancia: $distancia km');
        print('   - Duración: $duracion min');

        if (routePoints.isEmpty) {
          throw Exception('No se obtuvieron puntos de ruta');
        }

        return {
          'coordinates': routePoints,
          'distance': distancia,
          'duration': duracion,
        };
      }

      throw Exception('Respuesta inválida del servidor OSRM');
    } catch (e) {
      print('❌ Error al obtener ruta de OSRM: $e');
      
      // Reintentar si el error es por fallback de OSRM y no hemos excedido los intentos
      if (e.toString().contains('fallback') && intentos < maxIntentos) {
        print('🔄 Reintentando (${intentos + 1}/$maxIntentos)...');
        await Future.delayed(Duration(milliseconds: 1000)); // Esperar 1 segundo
        return obtenerRuta(origen, destino, intentos: intentos + 1);
      }
      
      print('⚠️ Usando FALLBACK (línea recta)');
      
      // Fallback: calcular distancia directa y estimar duración
      final distance = _calculateDirectDistance(origen, destino);
      
      return {
        'coordinates': [origen, destino],  // Línea recta
        'distance': distance,
        'duration': _estimateDuration(distance),
      };
    }
  }

  /// Calcula la distancia total de una ruta
  static double _calculateDistance(List<LatLng> points) {
    if (points.length < 2) return 0.0;

    double totalDistance = 0.0;
    for (int i = 0; i < points.length - 1; i++) {
      totalDistance += _calculateDirectDistance(points[i], points[i + 1]);
    }
    return totalDistance;
  }

  /// Calcula la distancia directa entre dos puntos (fórmula de Haversine)
  static double _calculateDirectDistance(LatLng point1, LatLng point2) {
    const Distance distance = Distance();
    return distance.as(LengthUnit.Kilometer, point1, point2);
  }

  /// Estima la duración del viaje en minutos basándose en la distancia
  /// Asume una velocidad promedio de 60 km/h
  static int _estimateDuration(double distanceKm) {
    const averageSpeedKmh = 60.0;
    final hours = distanceKm / averageSpeedKmh;
    return (hours * 60).round();
  }

  /// Obtiene instrucciones de navegación paso a paso
  static Future<List<String>> obtenerInstrucciones(LatLng origen, LatLng destino) async {
    try {
      final routeData = await obtenerRuta(origen, destino);
      
      // TODO: Parsear instrucciones detalladas desde ORS
      // Por ahora, devolver instrucciones básicas
      return [
        'Inicia en tu ubicación actual',
        'Dirígete hacia ${destino.latitude}, ${destino.longitude}',
        'Sigue la ruta marcada en el mapa',
        'Llegarás a tu destino en aproximadamente ${routeData['duration']} minutos',
      ];
    } catch (e) {
      print('Error al obtener instrucciones: $e');
      return [
        'Dirígete hacia el destino marcado en el mapa',
      ];
    }
  }
}
