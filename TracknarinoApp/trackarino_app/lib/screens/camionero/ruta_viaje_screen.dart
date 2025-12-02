import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/alerta_model.dart';
import '../../models/oportunidad_model.dart';
import '../../services/alerta_service.dart';
import '../../services/location_service.dart';
import '../../services/oportunidad_service.dart';
import '../../services/ors_service.dart';

class RutaViajeScreen extends StatefulWidget {
  final Oportunidad oportunidad;

  const RutaViajeScreen({super.key, required this.oportunidad});

  @override
  State<RutaViajeScreen> createState() => _RutaViajeScreenState();
}

class _RutaViajeScreenState extends State<RutaViajeScreen> {
  final MapController _mapController = MapController();
  LatLng? _currentPosition;
  LatLng? _destinoPosition;
  List<LatLng> _routePoints = [];
  bool _isLoadingRoute = true;
  String? _errorMessage;

  // Información de la ruta
  double? _distanciaKm;
  int? _duracionMinutos;
  String? _duracionTexto;

  // Alertas en la ruta
  List<dynamic> _alertasEnRuta = [];
  bool _cargandoAlertas = false;

  // Estado del viaje
  bool _viajeIniciado = false;
  DateTime? _horaInicio;

  StreamSubscription? _locationSubscription;

  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    // Verificar si el viaje ya está iniciado
    if (widget.oportunidad.estado == 'en_ruta') {
      _viajeIniciado = true;
      _horaInicio = DateTime.now(); // Usar hora actual como referencia
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      _initializeRoute();
    }
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initializeRoute() async {
    setState(() {
      _isLoadingRoute = true;
      _errorMessage = null;
    });

    try {
      // Esperar a que el frame actual termine de construirse
      await Future.delayed(Duration.zero);

      if (!mounted) return;

      // Solicitar permisos de ubicación
      final locationService = Provider.of<LocationService>(
        context,
        listen: false,
      );

      // Obtener ubicación actual
      final position = await locationService.getCurrentLocation();

      if (position == null) {
        setState(() {
          _errorMessage =
              'No se pudo obtener tu ubicación. Verifica los permisos en la configuración.';
          _isLoadingRoute = false;
        });
        return;
      }

      final currentLatLng = LatLng(position.latitude, position.longitude);

      // 3. Destino desde la oportunidad (simulado por ahora)
      // TODO: Agregar coordenadas reales a las oportunidades
      final destinoLatLng = _getDestinationCoordinates(
        widget.oportunidad.destino,
      );

      setState(() {
        _currentPosition = currentLatLng;
        _destinoPosition = destinoLatLng;
      });

      // 4. Obtener ruta desde ORS
      await _obtenerRuta(currentLatLng, destinoLatLng);

      // 5. Centrar mapa en la ruta
      if (_routePoints.isNotEmpty) {
        _centerMapOnRoute();
      }

      // 6. Suscribirse a actualizaciones de ubicación
      _locationSubscription = locationService.positionStream.listen((
        newPosition,
      ) {
        if (mounted) {
          setState(() {
            _currentPosition = LatLng(
              newPosition.latitude,
              newPosition.longitude,
            );
          });
        }
      });

      // 7. Si el viaje ya está iniciado, cargar alertas automáticamente
      if (_viajeIniciado) {
        await _cargarAlertasEnRuta();
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al cargar la ruta: $e';
        _isLoadingRoute = false;
      });
    }
  }

  Future<void> _obtenerRuta(LatLng origen, LatLng destino) async {
    try {
      print('🗺️ Iniciando cálculo de ruta...');
      final startTime = DateTime.now();

      final routeData = await ORSService.obtenerRuta(origen, destino);

      final duration = DateTime.now().difference(startTime);
      print('⏱️ Ruta calculada en ${duration.inMilliseconds}ms');

      setState(() {
        _routePoints = routeData['coordinates'] as List<LatLng>;
        _distanciaKm = routeData['distance'];
        _duracionMinutos = routeData['duration'];
        _duracionTexto = _formatDuration(_duracionMinutos!);
        _isLoadingRoute = false;
      });
    } catch (e) {
      debugPrint('Error al obtener ruta: $e');
      setState(() {
        _errorMessage = 'No se pudo calcular la ruta. Usando línea directa.';
        _routePoints = [origen, destino];
        _distanciaKm = _calculateDirectDistance(origen, destino);
        _duracionMinutos =
            (_distanciaKm! / 60 * 60).round(); // Asumiendo 60 km/h
        _duracionTexto = _formatDuration(_duracionMinutos!);
        _isLoadingRoute = false;
      });
    }
  }

  LatLng _getDestinationCoordinates(String destination) {
    // Coordenadas de ciudades de Nariño y Colombia
    final Map<String, LatLng> ciudades = {
      // Nariño (departamento)
      'Pasto': LatLng(1.2136, -77.2811),
      'Ipiales': LatLng(0.8292, -77.6419),
      'Tumaco': LatLng(1.8014, -78.7653),
      'Túquerres': LatLng(1.0869, -77.6169),
      'Samaniego': LatLng(1.3381, -77.5947),
      'La Unión': LatLng(1.6011, -77.1311),
      'Sandoná': LatLng(1.2839, -77.4686),
      'Buesaco': LatLng(1.3847, -77.1639),
      'La Florida': LatLng(1.3419, -77.4144),
      // Otras ciudades cercanas
      'Cali': LatLng(3.4516, -76.5320),
      'Popayán': LatLng(2.4419, -76.6063),
      'Bogotá': LatLng(4.7110, -74.0721),
    };

    // Buscar coincidencia parcial
    for (var entry in ciudades.entries) {
      if (destination.toLowerCase().contains(entry.key.toLowerCase())) {
        return entry.value;
      }
    }

    // Si no encuentra, usar Cali por defecto
    return ciudades['Cali']!;
  }

  double _calculateDirectDistance(LatLng point1, LatLng point2) {
    const Distance distance = Distance();
    return distance.as(LengthUnit.Kilometer, point1, point2);
  }

  String _formatDuration(int minutes) {
    if (minutes < 60) {
      return '$minutes min';
    } else {
      final hours = minutes ~/ 60;
      final mins = minutes % 60;
      return '${hours}h ${mins}min';
    }
  }

  void _centerMapOnRoute() {
    if (_routePoints.isEmpty) return;

    // Calcular bounds de la ruta
    double minLat = _routePoints[0].latitude;
    double maxLat = _routePoints[0].latitude;
    double minLng = _routePoints[0].longitude;
    double maxLng = _routePoints[0].longitude;

    for (var point in _routePoints) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLng) minLng = point.longitude;
      if (point.longitude > maxLng) maxLng = point.longitude;
    }

    final center = LatLng((minLat + maxLat) / 2, (minLng + maxLng) / 2);
    _mapController.move(center, 10.0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.oportunidad.titulo),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _mostrarInformacionViaje,
          ),
        ],
      ),
      body: Stack(
        children: [
          // Mapa
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              center: _currentPosition ?? LatLng(1.2136, -77.2811),
              zoom: 13.0,
            ),
            children: [
              TileLayer(
                urlTemplate:
                    "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                subdomains: const ['a', 'b', 'c'],
              ),

              // Línea de ruta
              if (_routePoints.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _routePoints,
                      strokeWidth: 4.0,
                      color: Colors.blue,
                    ),
                  ],
                ),

              // Marcadores
              MarkerLayer(
                markers: [
                  // Ubicación actual
                  if (_currentPosition != null)
                    Marker(
                      width: 50.0,
                      height: 50.0,
                      point: _currentPosition!,
                      builder:
                          (ctx) => Container(
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                            ),
                            child: const Icon(
                              Icons.navigation,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                    ),

                  // Destino
                  if (_destinoPosition != null)
                    Marker(
                      width: 50.0,
                      height: 50.0,
                      point: _destinoPosition!,
                      builder:
                          (ctx) => const Icon(
                            Icons.location_on,
                            color: Colors.red,
                            size: 50,
                          ),
                    ),

                  // Alertas en la ruta
                  ..._alertasEnRuta.map((alerta) {
                    return Marker(
                      width: 40.0,
                      height: 40.0,
                      point: LatLng(
                        alerta.coords['lat']!,
                        alerta.coords['lng']!,
                      ),
                      builder:
                          (ctx) => GestureDetector(
                            onTap: () => _mostrarDetalleAlerta(alerta),
                            child: Container(
                              decoration: BoxDecoration(
                                color: _getAlertaColor(alerta.tipo),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.3),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Icon(
                                _getAlertaIcon(alerta.tipo),
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                    );
                  }),
                ],
              ),
            ],
          ),

          // Panel de información
          if (_isLoadingRoute)
            Container(
              color: Colors.black54,
              child: Center(
                child: Card(
                  margin: const EdgeInsets.all(32),
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(
                          strokeWidth: 3,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Theme.of(context).primaryColor,
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Calculando la mejor ruta...',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Esto puede tomar unos segundos',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          if (_errorMessage != null && !_isLoadingRoute)
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Card(
                color: Colors.orange,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ),

          // Panel inferior con información
          if (!_isLoadingRoute && _distanciaKm != null)
            Positioned(left: 0, right: 0, bottom: 0, child: _buildInfoPanel()),

          // Botones de acción en esquinas superiores
          if (_viajeIniciado) ...[
            // Botón SOS en esquina superior izquierda
            Positioned(
              top: 16,
              left: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Botón SOS 112
                  FloatingActionButton(
                    heroTag: 'sos_button',
                    onPressed: _llamarSOS,
                    backgroundColor: Colors.red,
                    child: const Icon(Icons.sos, size: 32),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'SOS 112',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Botón crear alerta en esquina superior derecha
            Positioned(
              top: 16,
              right: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Botón de crear alerta
                  FloatingActionButton(
                    heroTag: 'crear_alerta',
                    onPressed: _mostrarCrearAlerta,
                    backgroundColor: Colors.orange,
                    child: const Icon(Icons.add_alert),
                  ),
                  const SizedBox(height: 8),
                  // Badge con número de alertas
                  if (_alertasEnRuta.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${_alertasEnRuta.length} alertas',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoPanel() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Indicador de arrastre
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Destino
                Row(
                  children: [
                    const Icon(Icons.location_on, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Destino',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          Text(
                            widget.oportunidad.destino,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const Divider(height: 24),

                // Información de la ruta
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem(
                      Icons.straighten,
                      '${_distanciaKm!.toStringAsFixed(1)} km',
                      'Distancia',
                    ),
                    _buildStatItem(
                      Icons.access_time,
                      _duracionTexto!,
                      'Tiempo est.',
                    ),
                    _buildStatItem(
                      Icons.attach_money,
                      '\$${widget.oportunidad.precio.toStringAsFixed(0)}',
                      'Pago',
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Botones de acción
                if (_viajeIniciado) ...[
                  // Cuando el viaje está iniciado, mostrar botones de finalizar y cancelar
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _cancelarViaje,
                          icon: const Icon(Icons.close),
                          label: const Text('Salir'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          onPressed: _finalizarViaje,
                          icon: const Icon(Icons.flag),
                          label: const Text('Finalizar viaje'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  // Cuando el viaje no está iniciado
                  Row(
                    children: [
                      // Botón RECHAZAR viaje
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final confirmar = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('¿Rechazar?'),
                                content: const Text('¿Deseas rechazar este viaje?'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, false),
                                    child: const Text('No'),
                                  ),
                                  ElevatedButton(
                                    onPressed: () => Navigator.pop(ctx, true),
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                    child: const Text('Rechazar'),
                                  ),
                                ],
                              ),
                            );
                            if (confirmar == true && mounted) {
                              try {
                                // Mostrar loading
                                showDialog(
                                  context: context,
                                  barrierDismissible: false,
                                  builder: (ctx) => const Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                );
                                
                                await OportunidadService.cancelarViaje(widget.oportunidad.id!);
                                
                                if (mounted) {
                                  // Cerrar loading
                                  Navigator.pop(context);
                                  
                                  // Mostrar mensaje de éxito
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('✅ Viaje rechazado correctamente'),
                                      backgroundColor: Colors.orange,
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                  
                                  // Cerrar pantalla de ruta y volver al listado
                                  Navigator.pop(context);
                                }
                              } catch (e) {
                                if (mounted) {
                                  // Cerrar loading si hay error
                                  Navigator.pop(context);
                                  
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('❌ Error al rechazar: $e'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            }
                          },
                          icon: const Icon(Icons.cancel, size: 18),
                          label: const Text('Rechazar', style: TextStyle(fontSize: 11)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _centerMapOnRoute,
                          icon: const Icon(Icons.center_focus_strong, size: 18),
                          label: const Text('Ver', style: TextStyle(fontSize: 11)),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          onPressed: _iniciarViaje,
                          icon: const Icon(Icons.play_arrow),
                          label: const Text('Iniciar viaje'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: Theme.of(context).primaryColor, size: 28),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }

  void _mostrarInformacionViaje() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Información del viaje'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Origen: ${widget.oportunidad.origen}'),
                Text('Destino: ${widget.oportunidad.destino}'),
                if (_distanciaKm != null)
                  Text('Distancia: ${_distanciaKm!.toStringAsFixed(1)} km'),
                if (_duracionTexto != null)
                  Text('Duración estimada: $_duracionTexto'),
                Text(
                  'Precio: \$${widget.oportunidad.precio.toStringAsFixed(0)}',
                ),
                if (widget.oportunidad.descripcion != null)
                  Text('Descripción: ${widget.oportunidad.descripcion}'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cerrar'),
              ),
            ],
          ),
    );
  }

  Future<bool> _mostrarDialogoPermisos() async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder:
              (dialogContext) => AlertDialog(
                title: Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      color: Theme.of(dialogContext).primaryColor,
                    ),
                    const SizedBox(width: 8),
                    const Text('Permisos de ubicación'),
                  ],
                ),
                content: const Text(
                  'Para mostrar la ruta y tu ubicación en tiempo real, necesitamos acceso a tu ubicación GPS.\n\n'
                  '¿Deseas permitir el acceso a tu ubicación?',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext, false),
                    child: const Text('No permitir'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(dialogContext, true),
                    child: const Text('Permitir'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(dialogContext).primaryColor,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
        ) ??
        false;
  }

  Future<void> _iniciarViaje() async {
    try {
      // Mostrar diálogo de confirmación con detalles del viaje
      final confirmar = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder:
            (dialogContext) => AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.local_shipping, color: Colors.green),
                  SizedBox(width: 8),
                  Text('Confirmar inicio de viaje'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '¿Estás listo para iniciar este viaje?',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _buildDetailRow(
                    Icons.route,
                    'Distancia',
                    '${_distanciaKm?.toStringAsFixed(1) ?? '0'} km',
                  ),
                  _buildDetailRow(
                    Icons.access_time,
                    'Duración',
                    _duracionTexto ?? '0 min',
                  ),
                  _buildDetailRow(
                    Icons.location_on,
                    'Destino',
                    widget.oportunidad.destino,
                  ),
                  _buildDetailRow(
                    Icons.attach_money,
                    'Pago',
                    '\$${widget.oportunidad.precio.toStringAsFixed(0)}',
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 16,
                          color: Colors.orange,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Recuerda reportar cualquier incidente durante el viaje',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton.icon(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('¡Iniciar viaje!'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
      );

      if (confirmar == true && mounted) {
        final scaffoldMessenger = ScaffoldMessenger.of(context);

        try {
          await OportunidadService.iniciarViaje(widget.oportunidad.id!);

          setState(() {
            _viajeIniciado = true;
            _horaInicio = DateTime.now();
          });

          // Iniciar tracking de ubicación
          final locationService = Provider.of<LocationService>(
            context,
            listen: false,
          );
          await locationService.startTracking();

          // Cargar alertas en la ruta
          await _cargarAlertasEnRuta();

          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          '¡Viaje iniciado!',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Duración estimada: $_duracionTexto • ${_alertasEnRuta.length} alertas en ruta',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 4),
            ),
          );
        } catch (e) {
          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: Text('Error al iniciar viaje: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error al mostrar diálogo: $e');
    }
  }

  Future<void> _finalizarViaje() async {
    try {
      // Calcular tiempo de viaje
      final tiempoTranscurrido =
          _horaInicio != null
              ? DateTime.now().difference(_horaInicio!).inMinutes
              : 0;

      // Mostrar diálogo de confirmación
      final confirmar = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder:
            (dialogContext) => AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.flag, color: Colors.green),
                  SizedBox(width: 8),
                  Text('Finalizar viaje'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '¿Has llegado al destino?',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _buildDetailRow(
                    Icons.location_on,
                    'Destino',
                    widget.oportunidad.destino,
                  ),
                  _buildDetailRow(
                    Icons.straighten,
                    'Distancia',
                    '${_distanciaKm?.toStringAsFixed(1) ?? '0'} km',
                  ),
                  _buildDetailRow(
                    Icons.timer,
                    'Tiempo',
                    '${tiempoTranscurrido} min',
                  ),
                  _buildDetailRow(
                    Icons.attach_money,
                    'Pago a recibir',
                    '\$${widget.oportunidad.precio.toStringAsFixed(0)}',
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 18,
                          color: Colors.green.shade700,
                        ),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Al finalizar, el contratista será notificado y podrás recibir tu pago.',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton.icon(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  icon: const Icon(Icons.check_circle),
                  label: const Text('Finalizar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
      );

      if (confirmar == true && mounted) {
        final scaffoldMessenger = ScaffoldMessenger.of(context);
        final navigator = Navigator.of(context);

        try {
          // Llamar al servicio para finalizar viaje
          await OportunidadService.finalizarViaje(widget.oportunidad.id!);

          // Detener tracking
          final locationService = Provider.of<LocationService>(
            context,
            listen: false,
          );
          locationService.stopTracking();

          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: Row(
                children: const [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '¡Viaje finalizado! El contratista ha sido notificado.',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );

          // Volver a la pantalla anterior después de un breve delay
          await Future.delayed(const Duration(milliseconds: 500));
          if (mounted) {
            navigator.pop(
              true,
            ); // Retornar true para indicar que el viaje finalizó
          }
        } catch (e) {
          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: Text('Error al finalizar viaje: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error al mostrar diálogo de finalización: $e');
    }
  }

  Future<void> _cancelarViaje() async {
    try {
      // Mostrar diálogo de confirmación
      final confirmar = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder:
            (dialogContext) => AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.warning, color: Colors.orange),
                  SizedBox(width: 8),
                  Text('Cancelar viaje'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '¿Estás seguro de que quieres salir del viaje?',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 18,
                          color: Colors.orange.shade700,
                        ),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'La carga volverá a estar disponible para otros camioneros.',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('No, continuar viaje'),
                ),
                ElevatedButton.icon(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  icon: const Icon(Icons.exit_to_app),
                  label: const Text('Sí, salir'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
      );

      if (confirmar == true && mounted) {
        final scaffoldMessenger = ScaffoldMessenger.of(context);
        final navigator = Navigator.of(context);

        try {
          // Llamar al servicio para cancelar viaje
          await OportunidadService.cancelarViaje(widget.oportunidad.id!);

          // Detener tracking
          final locationService = Provider.of<LocationService>(
            context,
            listen: false,
          );
          locationService.stopTracking();

          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: Row(
                children: const [
                  Icon(Icons.info, color: Colors.white),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Has salido del viaje. La carga está disponible nuevamente.',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 3),
            ),
          );

          // Volver a la pantalla anterior
          await Future.delayed(const Duration(milliseconds: 500));
          if (mounted) {
            navigator.pop(false); // Retornar false para indicar que se canceló
          }
        } catch (e) {
          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: Text('Error al cancelar viaje: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error al mostrar diálogo de cancelación: $e');
    }
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(
            '$label:',
            style: TextStyle(color: Colors.grey[600], fontSize: 13),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _cargarAlertasEnRuta() async {
    setState(() {
      _cargandoAlertas = true;
    });

    try {
      // Buscar alertas cercanas a toda la ruta
      if (_routePoints.isNotEmpty) {
        // Obtener alertas cercanas al punto medio de la ruta
        final puntoMedio = _routePoints[_routePoints.length ~/ 2];
        final geoPosition = Position(
          latitude: puntoMedio.latitude,
          longitude: puntoMedio.longitude,
          timestamp: DateTime.now(),
          accuracy: 0,
          altitude: 0,
          heading: 0,
          speed: 0,
          speedAccuracy: 0,
          altitudeAccuracy: 0,
          headingAccuracy: 0,
        );

        final alertas = await AlertaService.obtenerAlertasCercanas(geoPosition);

        if (mounted) {
          setState(() {
            _alertasEnRuta = alertas;
            _cargandoAlertas = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error al cargar alertas: $e');
      setState(() {
        _cargandoAlertas = false;
      });
    }
  }

  Color _getAlertaColor(String tipo) {
    switch (tipo.toLowerCase()) {
      case 'trancon':
        return Colors.orange;
      case 'sospecha':
        return Colors.purple;
      case 'intento_robo':
        return Colors.red.shade700;
      case 'robo':
        return Colors.red;
      case 'obstaculo':
        return Colors.yellow.shade700;
      case 'accidente':
        return Colors.red;
      case 'trafico':
        return Colors.orange;
      case 'obra':
        return Colors.yellow.shade700;
      case 'policia':
        return Colors.blue;
      case 'peligro':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  IconData _getAlertaIcon(String tipo) {
    switch (tipo.toLowerCase()) {
      case 'trancon':
        return Icons.traffic;
      case 'sospecha':
        return Icons.remove_red_eye;
      case 'intento_robo':
        return Icons.warning;
      case 'robo':
        return Icons.dangerous;
      case 'obstaculo':
        return Icons.block;
      case 'accidente':
        return Icons.car_crash;
      case 'trafico':
        return Icons.traffic;
      case 'obra':
        return Icons.construction;
      case 'policia':
        return Icons.local_police;
      case 'peligro':
        return Icons.warning;
      default:
        return Icons.info;
    }
  }

  void _mostrarDetalleAlerta(AlertaSeguridad alerta) {
    showDialog(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: Row(
              children: [
                Icon(
                  _getAlertaIcon(alerta.tipo),
                  color: _getAlertaColor(alerta.tipo),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    alerta.tipo.toUpperCase(),
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alerta.descripcion ?? 'Sin descripción',
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.person, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      'Reportado por: ${alerta.usuario}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Cerrar'),
              ),
            ],
          ),
    );
  }

  void _mostrarCrearAlerta() {
    if (_currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Esperando ubicación GPS...'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final descripcionController = TextEditingController();
    String tipoSeleccionado = 'trancon';

    showDialog(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.add_alert, color: Colors.orange),
                SizedBox(width: 8),
                Text('Crear Alerta de Seguridad'),
              ],
            ),
            content: StatefulBuilder(
              builder:
                  (context, setDialogState) => Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Tipo de alerta:'),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: tipoSeleccionado,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        items:
                            [
                                  {'value': 'trancon', 'label': 'Trancón'},
                                  {'value': 'sospecha', 'label': 'Sospecha'},
                                  {
                                    'value': 'intento_robo',
                                    'label': 'Intento de Robo',
                                  },
                                  {'value': 'robo', 'label': 'Robo'},
                                  {'value': 'obstaculo', 'label': 'Obstáculo'},
                                ]
                                .map(
                                  (tipo) => DropdownMenuItem(
                                    value: tipo['value'],
                                    child: Row(
                                      children: [
                                        Icon(
                                          _getAlertaIcon(tipo['value']!),
                                          size: 16,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(tipo['label']!),
                                      ],
                                    ),
                                  ),
                                )
                                .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setDialogState(() {
                              tipoSeleccionado = value;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      const Text('Descripción:'),
                      const SizedBox(height: 8),
                      TextField(
                        controller: descripcionController,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: 'Describe el incidente...',
                        ),
                        maxLines: 3,
                      ),
                    ],
                  ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Cancelar'),
              ),
              ElevatedButton.icon(
                onPressed: () async {
                  if (descripcionController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Por favor ingresa una descripción'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                    return;
                  }

                  Navigator.of(dialogContext).pop();

                  try {
                    await AlertaService.crearAlerta(
                      tipo: tipoSeleccionado,
                      coords: {
                        'lat': _currentPosition!.latitude,
                        'lng': _currentPosition!.longitude,
                      },
                      descripcion: descripcionController.text.trim(),
                    );

                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              Icon(
                                _getAlertaIcon(tipoSeleccionado),
                                color: Colors.white,
                              ),
                              const SizedBox(width: 8),
                              const Expanded(
                                child: Text(
                                  '¡Alerta creada! Gracias por reportar',
                                ),
                              ),
                            ],
                          ),
                          backgroundColor: Colors.green,
                          duration: const Duration(seconds: 3),
                        ),
                      );

                      // Recargar alertas
                      await _cargarAlertasEnRuta();
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error al crear alerta: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.check),
                label: const Text('Crear'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
    );
  }

  Future<void> _llamarSOS() async {
    // Mostrar diálogo de confirmación antes de llamar
    final confirmar = await showDialog<bool>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.sos, color: Colors.red, size: 32),
                SizedBox(width: 12),
                Text('Llamada de Emergencia'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '¿Estás seguro de llamar al 112?',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '🚨 Número de emergencias: 112',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Úsalo solo en caso de emergencia real',
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton.icon(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                icon: const Icon(Icons.phone),
                label: const Text('Llamar al 112'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
    );

    if (confirmar == true) {
      try {
        final Uri phoneUri = Uri(scheme: 'tel', path: '112');

        if (await canLaunchUrl(phoneUri)) {
          await launchUrl(phoneUri);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Row(
                  children: [
                    Icon(Icons.phone, color: Colors.white),
                    SizedBox(width: 8),
                    Expanded(child: Text('Iniciando llamada al 112...')),
                  ],
                ),
                backgroundColor: Colors.red,
                duration: Duration(seconds: 2),
              ),
            );
          }
        } else {
          throw 'No se puede realizar la llamada';
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al llamar: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}
