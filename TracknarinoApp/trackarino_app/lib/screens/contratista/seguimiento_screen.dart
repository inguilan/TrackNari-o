import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as google_maps;
import '../../services/location_service.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latlong;
import 'package:google_maps_flutter_platform_interface/google_maps_flutter_platform_interface.dart' show BitmapDescriptor;
import '../../utils/flutter_map_fixes.dart'; // Importar el archivo de parches

class SeguimientoScreen extends StatefulWidget {
  const SeguimientoScreen({super.key});

  @override
  State<SeguimientoScreen> createState() => _SeguimientoScreenState();
}

class _SeguimientoScreenState extends State<SeguimientoScreen> with TickerProviderStateMixin {
  google_maps.GoogleMapController? _mapController;
  final Set<google_maps.Marker> _markers = {};
  final Set<google_maps.Polyline> _polylines = {}; // Para rutas entre puntos
  final Map<String, dynamic> _camioneros = {};
  bool _isLoading = true;
  String _errorMessage = '';
  bool _isBottomSheetExpanded = false;
  Timer? _updateTimer;
  bool _siguiendoCamionero = false; // Para seguir automáticamente al camionero seleccionado
  String? _camioneroSeleccionadoId;
  
  // Centro inicial del mapa (Pasto, Nariño)
  final google_maps.CameraPosition _initialPosition = const google_maps.CameraPosition(
    target: google_maps.LatLng(1.2136, -77.2811),
    zoom: 12,
  );

  // Controlador para animación del panel deslizante
  late AnimationController _animationController;
  
  // Íconos personalizados para los camioneros
  BitmapDescriptor? _carIcon;

  @override
  void initState() {
    super.initState();
    _loadCustomMapIcons();
    _cargarUbicacionesCamioneros();
    
    _animationController = AnimationController(
      vsync: this, 
      duration: const Duration(milliseconds: 300)
    );
    
    // Configurar actualizaciones periódicas de ubicación
    _updateTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _cargarUbicacionesCamioneros();
    });
  }
  
  @override
  void dispose() {
    _mapController?.dispose();
    _animationController.dispose();
    _updateTimer?.cancel();
    super.dispose();
  }

  // Cargar íconos personalizados
  Future<void> _loadCustomMapIcons() async {
    try {
      // Intentar cargar icono personalizado
      final Uint8List markerIcon = await _getBytesFromAsset('assets/images/vehicle_top.png', 80);
      _carIcon = BitmapDescriptor.bytes(markerIcon);
    } catch (e) {
      // Si falla, usar icono por defecto
      print('No se pudo cargar icono personalizado, usando icono por defecto: $e');
      _carIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);
    }
    if (mounted) {
      setState(() {});
    }
  }

  // Convertir imagen de asset a bytes para uso como marcador
  Future<Uint8List> _getBytesFromAsset(String path, int width) async {
    ByteData data = await rootBundle.load(path);
    ui.Codec codec = await ui.instantiateImageCodec(
      data.buffer.asUint8List(), 
      targetWidth: width
    );
    ui.FrameInfo fi = await codec.getNextFrame();
    return (await fi.image.toByteData(format: ui.ImageByteFormat.png))!.buffer.asUint8List();
  }

  Future<void> _cargarUbicacionesCamioneros() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Aquí obtendríamos datos reales del backend
      // Por ahora usamos una mezcla de datos simulados y datos del servicio
      final locationService = Provider.of<LocationService>(context, listen: false);
      
      final camionerosEnRuta = [
        {
          'id': '1',
          'nombre': 'Carlos Pérez',
          'telefono': '300-123-4567',
          'ubicacion': const google_maps.LatLng(1.2236, -77.2751),
          'ubicacionAnterior': const google_maps.LatLng(1.2230, -77.2745), // Para calcular orientación
          'rumbo': 45.0, // Orientación simulada en grados
          'placaVehiculo': 'ABC123',
          'ultimaActualizacion': DateTime.now().subtract(const Duration(minutes: 5)),
          'enRuta': true,
          'destino': 'Ipiales',
          'origen': 'Pasto',
          'estado': 'En camino',
          'tiempoEstimado': '2h 30min',
          'distanciaRecorrida': '45 km',
          'carga': 'Alimentos perecederos',
        },
        {
          'id': '2',
          'nombre': 'María López',
          'telefono': '310-987-6543',
          'ubicacion': const google_maps.LatLng(1.2036, -77.2911),
          'ubicacionAnterior': const google_maps.LatLng(1.2040, -77.2920),
          'rumbo': 120.0,
          'placaVehiculo': 'XYZ789',
          'ultimaActualizacion': DateTime.now().subtract(const Duration(minutes: 15)),
          'enRuta': true,
          'destino': 'Tumaco',
          'origen': 'Pasto',
          'estado': 'Entrega próxima',
          'tiempoEstimado': '3h 15min',
          'distanciaRecorrida': '120 km',
          'carga': 'Material de construcción',
        },
        {
          'id': '3',
          'nombre': 'Juan García',
          'telefono': '321-456-7890',
          'ubicacion': const google_maps.LatLng(1.1936, -77.3051),
          'ubicacionAnterior': const google_maps.LatLng(1.1930, -77.3040),
          'rumbo': 220.0,
          'placaVehiculo': 'DEF456',
          'ultimaActualizacion': DateTime.now().subtract(const Duration(minutes: 2)),
          'enRuta': true,
          'destino': 'Popayán',
          'origen': 'Pasto',
          'estado': 'Recién iniciado',
          'tiempoEstimado': '4h 45min',
          'distanciaRecorrida': '10 km',
          'carga': 'Productos electrónicos',
        },
      ];

      // Intentar obtener ubicaciones reales (esto sería reemplazado por llamadas a la API)
      // Por ejemplo: ubicación = await locationService.obtenerUltimaPosicionCamionero(id);

      setState(() {
        _markers.clear();
        _camioneros.clear();
        
        for (var camionero in camionerosEnRuta) {
          _camioneros[camionero['id'] as String] = camionero;
          _agregarMarker(camionero);
        }
        
        _actualizarPolylines();
        _isLoading = false;
        
        // Si hay un camionero seleccionado, actualizar la vista del mapa
        if (_camioneroSeleccionadoId != null && _siguiendoCamionero) {
          final camionero = _camioneros[_camioneroSeleccionadoId];
          if (camionero != null) {
            _mapController?.animateCamera(
              google_maps.CameraUpdate.newLatLngZoom(
                camionero['ubicacion'],
                16,
              ),
            );
          }
        }
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al cargar ubicaciones: $e';
        _isLoading = false;
      });
    }
  }

  void _agregarMarker(Map<String, dynamic> camionero) {
    final markerId = google_maps.MarkerId(camionero['id'] as String);
    
    // Calcular rotación del marcador basado en el rumbo
    double rotacion = camionero['rumbo']?.toDouble() ?? 0.0;
    
    // Si tenemos acceso al servicio de ubicación, podemos calcular la rotación
    // basados en la ubicación anterior y actual
    if (camionero.containsKey('ubicacionAnterior') && camionero.containsKey('ubicacion')) {
      final locationService = Provider.of<LocationService>(context, listen: false);
      final ubicacionAnterior = camionero['ubicacionAnterior'] as google_maps.LatLng;
      final ubicacionActual = camionero['ubicacion'] as google_maps.LatLng;
      
      rotacion = locationService.calculateHeading(ubicacionAnterior, ubicacionActual);
    }
    
    final marker = google_maps.Marker(
      markerId: markerId,
      position: camionero['ubicacion'],
      rotation: rotacion,
      flat: true, // Importante para que la rotación funcione correctamente
      anchor: const Offset(0.5, 0.5), // Centrar el ícono en la posición
      infoWindow: google_maps.InfoWindow(
        title: camionero['nombre'] as String,
        snippet: 'Destino: ${camionero['destino'] as String}',
      ),
      icon: _carIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      onTap: () {
        _mostrarDetallesCamionero(camionero);
      },
    );

    setState(() {
      _markers.add(marker);
    });
  }
  
  // Actualizar líneas de ruta entre puntos
  void _actualizarPolylines() {
    _polylines.clear();
    
    // Aquí obtendrías rutas reales, por ahora hacemos rutas simples entre origen y destino
    if (_camioneroSeleccionadoId != null) {
      final camionero = _camioneros[_camioneroSeleccionadoId];
      if (camionero != null && camionero.containsKey('origen') && camionero.containsKey('destino')) {
        // En una implementación real, aquí llamarías a una API como Google Directions para obtener la ruta
        // Por ahora simplemente trazamos una línea directa
        _polylines.add(
          google_maps.Polyline(
            polylineId: google_maps.PolylineId('ruta_${camionero['id']}'),
            points: [
              camionero['ubicacion'],
              google_maps.LatLng(1.2136, -77.2811), // Simulando un punto de destino
            ],
            color: Colors.blue,
            width: 4,
          ),
        );
      }
    }
  }
  
  void _seleccionarCamionero(String id) {
    setState(() {
      _camioneroSeleccionadoId = id;
      _siguiendoCamionero = true;
      _actualizarPolylines();
      
      // Centrar el mapa en la ubicación del camionero
      final camionero = _camioneros[id];
      if (camionero != null) {
        _mapController?.animateCamera(
          google_maps.CameraUpdate.newLatLngZoom(
            camionero['ubicacion'],
            16,
          ),
        );
      }
    });
  }

  void _mostrarDetallesCamionero(Map<String, dynamic> camionero) {
    // Seleccionar el camionero automáticamente
    _seleccionarCamionero(camionero['id']);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.5,
          minChildSize: 0.3,
          maxChildSize: 0.7,
          builder: (_, controller) {
            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withAlpha(128),
                    spreadRadius: 2,
                    blurRadius: 7,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.all(24),
                children: [
                  // Indicador de arrastre
                  Center(
                    child: Container(
                      height: 5,
                      width: 50,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Encabezado con nombre y estado
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Theme.of(context).primaryColor,
                        radius: 24,
                        child: const Icon(Icons.person, color: Colors.white, size: 30),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              camionero['nombre'] as String,
                              style: Theme.of(context).textTheme.titleLarge,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.green.withAlpha(26),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: Colors.green,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    camionero['estado'] as String,
                                    style: const TextStyle(
                                      color: Colors.green,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Detalles de ruta
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Column(
                              children: [
                                const Icon(
                                  Icons.circle, 
                                  color: Colors.green,
                                  size: 14,
                                ),
                                Container(
                                  width: 2,
                                  height: 30,
                                  color: Colors.grey[300],
                                ),
                                const Icon(
                                  Icons.location_on,
                                  color: Colors.red,
                                  size: 14,
                                ),
                              ],
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    camionero['origen'] as String,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 30),
                                  Text(
                                    camionero['destino'] as String,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        
                        const Divider(height: 30),
                        
                        // Información adicional
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildInfoItem(
                              Icons.timer, 
                              camionero['tiempoEstimado'] as String, 
                              'Tiempo est.'
                            ),
                            _buildInfoItem(
                              Icons.route, 
                              camionero['distanciaRecorrida'] as String, 
                              'Recorrido'
                            ),
                            _buildInfoItem(
                              Icons.inventory_2, 
                              camionero['carga'] as String, 
                              'Carga'
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Información de contacto
                  _buildInfoRow('Placa', camionero['placaVehiculo'] as String),
                  _buildInfoRow('Teléfono', camionero['telefono'] as String),
                  _buildInfoRow(
                    'Última actualización', 
                    _formatTimeDifference(camionero['ultimaActualizacion'] as DateTime),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Botones de acción
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            // Centrar mapa en el camionero
                            _mapController?.animateCamera(
                              google_maps.CameraUpdate.newLatLngZoom(
                                camionero['ubicacion'],
                                16,
                              ),
                            );
                            _siguiendoCamionero = true;
                            Navigator.pop(context);
                          },
                          icon: const Icon(Icons.map),
                          label: const Text('VER EN MAPA'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            // Simular llamada telefónica
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Llamando al camionero...')),
                            );
                          },
                          icon: const Icon(Icons.phone),
                          label: const Text('LLAMAR'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: Theme.of(context).primaryColor),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  String _formatTimeDifference(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inMinutes < 60) {
      return 'Hace ${difference.inMinutes} min';
    } else if (difference.inHours < 24) {
      return 'Hace ${difference.inHours} h';
    } else {
      return 'Hace ${difference.inDays} días';
    }
  }

  void _toggleBottomSheet() {
    setState(() {
      _isBottomSheetExpanded = !_isBottomSheetExpanded;
    });
    
    if (_isBottomSheetExpanded) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }
  
  void _toggleSeguimientoCamionero() {
    setState(() {
      _siguiendoCamionero = !_siguiendoCamionero;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Seguimiento de Camioneros'),
      ),
      body: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              center: latlong.LatLng(1.2136, -77.2811),
              zoom: 12.0,
            ),
            children: [
              TileLayer(
                urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                subdomains: const ['a', 'b', 'c'],
              ),
              MarkerLayer(
                markers: [
                  // Crear marcadores para cada camionero en la lista _camioneros
                  ..._camioneros.values.map((camionero) => Marker(
                    width: 40.0,
                    height: 40.0,
                    point: latlong.LatLng(
                      (camionero['ubicacion'] as google_maps.LatLng).latitude,
                      (camionero['ubicacion'] as google_maps.LatLng).longitude,
                    ),
                    builder: (ctx) => Stack(
                      children: [
                        const Icon(
                          Icons.location_on,
                          color: Colors.red,
                          size: 40,
                        ),
                        Positioned(
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              camionero['nombre'].toString().substring(0, 1),
                              style: Theme.of(context).textTheme.titleLarge,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )),
                  // Marcador para centro de referencia
                  Marker(
                    width: 40.0,
                    height: 40.0,
                    point: latlong.LatLng(1.2136, -77.2811),
                    builder: (ctx) => const Icon(Icons.location_on, color: Colors.blue),
                  ),
                ],
              ),
            ],
          ),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
          if (_errorMessage.isNotEmpty)
            Center(
              child: Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _errorMessage,
                  style: const TextStyle(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Centrar mapa en los camioneros disponibles
          if (_markers.isNotEmpty) {
            final bounds = _calculateBounds();
            try {
              _mapController?.animateCamera(
                google_maps.CameraUpdate.newLatLngBounds(bounds, 50),
              );
            } catch (e) {
              debugPrint('Error al centrar mapa: $e');
              // Centrar en una posición fija como fallback
              _mapController?.animateCamera(
                google_maps.CameraUpdate.newLatLngZoom(
                  google_maps.LatLng(1.2136, -77.2811),
                  12,
                ),
              );
            }
          }
        },
        child: const Icon(Icons.center_focus_strong),
      ),
    );
  }

  // Calcular los límites para mostrar todos los marcadores en el mapa
  google_maps.LatLngBounds _calculateBounds() {
    double minLat = 90;
    double maxLat = -90;
    double minLng = 180;
    double maxLng = -180;
    
    for (final marker in _markers) {
      final position = marker.position;
      
      if (position.latitude < minLat) minLat = position.latitude;
      if (position.latitude > maxLat) maxLat = position.latitude;
      if (position.longitude < minLng) minLng = position.longitude;
      if (position.longitude > maxLng) maxLng = position.longitude;
    }
    
    return google_maps.LatLngBounds(
      southwest: google_maps.LatLng(minLat, minLng),
      northeast: google_maps.LatLng(maxLat, maxLng),
    );
  }
} 