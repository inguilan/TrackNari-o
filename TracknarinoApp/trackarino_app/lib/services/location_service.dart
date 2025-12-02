import 'dart:async';
import 'dart:math';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' show LatLng;
import '../config/api_config.dart';
import '../models/ubicacion_model.dart';
import 'api_service.dart';
import 'dart:math' as math;

class LocationService extends ChangeNotifier {
  Position? _lastPosition;
  Position? _currentPosition;
  final StreamController<Position> _positionController = StreamController<Position>.broadcast();
  StreamSubscription<Position>? _positionStreamSubscription;
  double _heading = 0.0; // Rumbo/dirección en grados
  bool _isTracking = false;
  final int _updateInterval = 15; // Actualizar cada 15 segundos
  String? _camioneroId;

  // Getters
  Stream<Position> get positionStream => _positionController.stream;
  Position? get lastPosition => _lastPosition;
  Position? get currentPosition => _currentPosition;
  double get heading => _heading;
  bool get isTracking => _isTracking;

  // Inicializa el servicio
  Future<void> init(String camioneroId) async {
    _camioneroId = camioneroId;
    await _checkLocationPermission();
  }

  // Verificar permisos de ubicación
  Future<bool> _checkLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Verificar si el servicio de ubicación está habilitado
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    // Verificar permisos
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  // Obtener la ubicación actual
  Future<Position?> getCurrentLocation() async {
    final hasPermission = await _checkLocationPermission();
    if (!hasPermission) return null;

    try {
      // Usar la mejor precisión posible
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
        timeLimit: const Duration(seconds: 10),
      );
      
      debugPrint('📍 Ubicación obtenida: ${position.latitude}, ${position.longitude}');
      debugPrint('   Precisión: ${position.accuracy}m');
      
      _currentPosition = position;
      notifyListeners();
      return position;
    } catch (e) {
      debugPrint('❌ Error al obtener ubicación: $e');
      
      // Intentar con precisión media si falla
      try {
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        _currentPosition = position;
        notifyListeners();
        return position;
      } catch (e2) {
        debugPrint('❌ Error al obtener ubicación (intento 2): $e2');
        return null;
      }
    }
  }

  // Iniciar seguimiento de ubicación
  Future<void> startTracking() async {
    if (_isTracking) return;
    
    final hasPermission = await _checkLocationPermission();
    if (!hasPermission) return;

    try {
      // Configuración optimizada para mejor precisión
      const locationSettings = LocationSettings(
        accuracy: LocationAccuracy.best, // Mejor precisión posible
        distanceFilter: 5, // Actualizar cada 5 metros de distancia
        timeLimit: Duration(seconds: 10), // Máximo cada 10 segundos
      );

      _positionStreamSubscription = Geolocator.getPositionStream(locationSettings: locationSettings)
          .listen(_updatePosition);
      
      _isTracking = true;
      debugPrint('✅ Tracking de ubicación iniciado');
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error al iniciar tracking: $e');
    }
  }

  // Detener seguimiento de ubicación
  void stopTracking() {
    _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;
    _isTracking = false;
    notifyListeners();
  }

  // Actualizar posición y calcular rumbo
  void _updatePosition(Position position) {
    // Guardar posición anterior
    if (_currentPosition != null) {
      _lastPosition = _currentPosition;
    }
    
    // Actualizar posición actual
    _currentPosition = position;
    
    // Calcular rumbo si hay posición anterior
    if (_lastPosition != null) {
      _heading = _calculateHeading(
        _lastPosition!.latitude, 
        _lastPosition!.longitude,
        _currentPosition!.latitude,
        _currentPosition!.longitude
      );
    }
    
    // Enviar ubicación al servidor
    if (_camioneroId != null) {
      sendLocationToServer(position);
    }
    
    // Notificar a los listeners
    _positionController.add(position);
    notifyListeners();
  }

  // Calcular rumbo/dirección en grados (0-360)
  double _calculateHeading(double lat1, double lon1, double lat2, double lon2) {
    // Convertir a radianes
    double lat1Rad = lat1 * (pi / 180);
    double lon1Rad = lon1 * (pi / 180);
    double lat2Rad = lat2 * (pi / 180);
    double lon2Rad = lon2 * (pi / 180);
    
    // Diferencia de longitud
    double dLon = lon2Rad - lon1Rad;
    
    // Cálculo del rumbo (bearing)
    double y = sin(dLon) * cos(lat2Rad);
    double x = cos(lat1Rad) * sin(lat2Rad) - sin(lat1Rad) * cos(lat2Rad) * cos(dLon);
    double heading = atan2(y, x) * (180 / pi);
    
    // Normalizar a 0-360
    return (heading + 360) % 360;
  }

  // Enviar ubicación al servidor
  Future<void> sendLocationToServer(Position position) async {
    if (_camioneroId == null) return;

    try {
      final data = {
        'latitud': position.latitude,
        'longitud': position.longitude,
        'velocidad': position.speed,
        'precision': position.accuracy,
        'rumbo': _heading,
        'timestamp': DateTime.now().toIso8601String(),
        'camioneroId': _camioneroId,
      };

      await ApiService.post('${ApiConfig.ubicacion}/actualizar', data);
    } catch (e) {
      print('Error al enviar ubicación al servidor: $e');
    }
  }

  // Obtener la última ubicación de un camionero
  Future<Ubicacion?> obtenerUltimaPosicionCamionero(String idCamionero) async {
    try {
      final response = await ApiService.get(
        '${ApiConfig.ubicacion}/ultima/$idCamionero'
      );
      
      return Ubicacion.fromJson(response);
    } catch (e) {
      print('Error al obtener última posición: $e');
      return null;
    }
  }

  // Calcular el ángulo entre dos ubicaciones para orientación del marker
  double calculateHeading(LatLng start, LatLng end) {
    double lat1 = start.latitude * pi / 180;
    double lon1 = start.longitude * pi / 180;
    double lat2 = end.latitude * pi / 180;
    double lon2 = end.longitude * pi / 180;
    
    double dLon = lon2 - lon1;
    double y = sin(dLon) * cos(lat2);
    double x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon);
    
    double bearing = atan2(y, x);
    bearing = bearing * 180 / pi;
    bearing = (bearing + 360) % 360;
    
    return bearing;
  }

  // Generar una ubicación simulada cerca de otra ubicación
  Position generateNearbyPosition(Position basePosition) {
    Random random = Random();
    
    // Generar desplazamientos aleatorios (entre -0.001 y 0.001 grados)
    double latOffset = (random.nextDouble() * 0.002) - 0.001;
    double lonOffset = (random.nextDouble() * 0.002) - 0.001;
    
    return Position(
      latitude: basePosition.latitude + latOffset,
      longitude: basePosition.longitude + lonOffset,
      timestamp: DateTime.now(),
      accuracy: basePosition.accuracy,
      altitude: basePosition.altitude,
      heading: basePosition.heading,
      speed: 5.0 + random.nextDouble() * 20.0, // Velocidad entre 5 y 25 m/s
      speedAccuracy: basePosition.speedAccuracy,
      floor: basePosition.floor,
      isMocked: true,
      altitudeAccuracy: basePosition.altitudeAccuracy,
      headingAccuracy: basePosition.headingAccuracy,
    );
  }

  @override
  void dispose() {
    stopTracking();
    super.dispose();
  }
} 