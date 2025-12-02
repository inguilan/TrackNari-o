import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/location_service.dart';
import '../../services/alerta_service.dart';
import '../../services/oportunidad_service.dart';
import '../../services/ors_service.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:math' as math;
import '../../models/oportunidad_model.dart';
import '../../models/alerta_model.dart';
import '../../screens/camionero/alertas_screen.dart';
import '../../screens/camionero/perfil_camionero_screen.dart';
import '../../screens/camionero/oportunidades_screen.dart';
import '../../screens/camionero/ruta_viaje_screen.dart';
import '../../widgets/viaje_activo_banner.dart';
import '../../utils/flutter_map_fixes.dart';

class CamioneroHomeScreen extends StatefulWidget {
  final User usuario;

  const CamioneroHomeScreen({
    super.key,
    required this.usuario,
  });

  @override
  State<CamioneroHomeScreen> createState() => _CamioneroHomeScreenState();
}

class _CamioneroHomeScreenState extends State<CamioneroHomeScreen> {
  int _selectedIndex = 0;
  bool _isLoading = false;
  final LocationService _locationService = LocationService();
  final MapController _mapController = MapController();
  LatLng? _currentPosition;
  LatLng? _destinoPosition;
  
  bool _isFollowingUser = true;
  final List<Oportunidad> _oportunidadesAsignadas = [];
  List<AlertaSeguridad> _alertasCercanas = [];
  bool _isDisponible = false;
  
  // Viaje activo
  Oportunidad? _viajeActivo;
  List<LatLng> _rutaActiva = [];
  bool _cargandoRuta = false;

  @override
  void initState() {
    super.initState();
    _initLocationTracking();
    _cargarOportunidades();
    _initializeLocation();
    _cargarEstadoDisponible();
    _cargarAlertasCercanas();
    _cargarViajeActivo(); // Cargar viaje activo al iniciar
    
    // Coordenadas simuladas para pruebas (Pasto - Nariño)
    _destinoPosition = LatLng(1.2136, -77.2811);
  }

  // Cargar viaje activo del camionero
  Future<void> _cargarViajeActivo() async {
    try {
      final viajeActivo = await OportunidadService.obtenerViajeActivo();
      
      if (viajeActivo != null && mounted) {
        setState(() {
          _viajeActivo = viajeActivo;
        });
        
        // Si hay viaje activo, cargar la ruta
        await _cargarRutaActiva(viajeActivo);
      }
    } catch (e) {
      debugPrint('Error al cargar viaje activo: $e');
    }
  }

  // Cargar ruta del viaje activo
  Future<void> _cargarRutaActiva(Oportunidad oportunidad) async {
    setState(() {
      _cargandoRuta = true;
    });

    try {
      final position = await _locationService.getCurrentLocation();
      if (position == null) return;

      final origen = LatLng(position.latitude, position.longitude);
      final destino = _getDestinationCoordinates(oportunidad.destino);

      final routeData = await ORSService.obtenerRuta(origen, destino);
      
      if (mounted) {
        setState(() {
          _rutaActiva = routeData['coordinates'] as List<LatLng>;
          _destinoPosition = destino;
          _cargandoRuta = false;
        });
      }
    } catch (e) {
      debugPrint('Error al cargar ruta activa: $e');
      setState(() {
        _cargandoRuta = false;
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

  // Cargar estado disponible guardado
  Future<void> _cargarEstadoDisponible() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final disponible = await authService.obtenerEstadoDisponible();
    setState(() {
      _isDisponible = disponible;
    });
  }

  // Cargar alertas cercanas para mostrar en el mapa
  Future<void> _cargarAlertasCercanas() async {
    try {
      final position = await _locationService.getCurrentLocation();
      if (position != null) {
        final alertas = await AlertaService.obtenerAlertasCercanas(position);
        if (mounted) {
          setState(() {
            _alertasCercanas = alertas;
          });
        }
      }
    } catch (e) {
      debugPrint('Error al cargar alertas cercanas: $e');
    }
  }

  // Iniciar el seguimiento de ubicación
  Future<void> _initLocationTracking() async {
    final locationService = Provider.of<LocationService>(context, listen: false);
    await locationService.startTracking();
  }

  // Cargar oportunidades asignadas al camionero
  Future<void> _cargarOportunidades() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Esta es una función que necesitarías implementar en oportunidadService
      // _oportunidadesAsignadas = await OportunidadService.obtenerOportunidadesAsignadas(widget.usuario.id!);
      
      // Por ahora, usaremos un placeholder
    } catch (e) {
      debugPrint('Error al cargar oportunidades: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _initializeLocation() async {
    try {
      // Iniciar el servicio de localización
      if (widget.usuario.id != null) {
        await _locationService.init(widget.usuario.id!);
      }
      
      // Obtener posición actual
      final position = await _locationService.getCurrentLocation();
      
      if (position != null && mounted) {
        final newLocation = LatLng(position.latitude, position.longitude);
        setState(() {
          _currentPosition = newLocation;
          _isLoading = false;
        });
        
        // Hacer zoom inicial a ubicación actual (estilo Uber)
        _mapController.move(newLocation, 16.0);
      }
      
      // Suscribirse a actualizaciones de posición
      _locationService.positionStream.listen((position) {
        if (mounted) {
          setState(() {
            _currentPosition = LatLng(position.latitude, position.longitude);
          });
          
          // Centrar mapa si está siguiendo al usuario
          if (_isFollowingUser) {
            _mapController.move(_currentPosition!, _mapController.zoom);
          }
        }
      });
    } catch (e) {
      debugPrint('Error al inicializar ubicación: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          // Usar coordenadas predeterminadas para pruebas (Pasto)
          _currentPosition = LatLng(1.2053, -77.2886);
        });
      }
    }
  }

  void _toggleFollowUser() {
    setState(() {
      _isFollowingUser = !_isFollowingUser;
      
      if (_isFollowingUser && _currentPosition != null) {
        _mapController.move(_currentPosition!, _mapController.zoom);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tracknariño - Camionero'),
        actions: [
          IconButton(
            onPressed: () async {
              await Provider.of<AuthService>(context, listen: false).logout();
            },
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _selectedIndex == 3
              ? PerfilCamioneroScreen(usuario: widget.usuario)
              : Stack(
                  children: [
                    // Mostrar mapa solo en la pantalla de inicio
                    if (_selectedIndex == 0) _buildMap(),
                    // Mostrar lista de oportunidades
                    if (_selectedIndex == 1) _buildOportunidadesList(),
                    // Mostrar alertas
                    if (_selectedIndex == 2) _buildAlertas(),
                    // Panel de estado
                    if (_selectedIndex != 3) _buildStatusPanel(),
                  ],
                ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Inicio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.local_shipping),
            label: 'Oportunidades',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.warning),
            label: 'Alertas',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }

  Widget _buildMap() {
    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            center: _currentPosition ?? LatLng(1.2053, -77.2886),
            zoom: 16.0,
            onPositionChanged: (position, hasGesture) {
              if (hasGesture) {
                setState(() {
                  _isFollowingUser = false;
                });
              }
            },
          ),
          children: [
            TileLayer(
              urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
              subdomains: const ['a', 'b', 'c'],
            ),
            // Polyline de la ruta activa
            if (_rutaActiva.isNotEmpty)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: _rutaActiva,
                    strokeWidth: 4.0,
                    color: Colors.blue,
                  ),
                ],
              ),
            MarkerLayer(
              markers: [
                if (_currentPosition != null)
                  Marker(
                    width: 40.0,
                    height: 40.0,
                    point: _currentPosition!,
                    builder: (ctx) => const Icon(
                      Icons.location_on,
                      color: Colors.blue,
                      size: 40,
                    ),
                  ),
                if (_destinoPosition != null)
                  Marker(
                    width: 40.0,
                    height: 40.0,
                    point: _destinoPosition!,
                    builder: (ctx) => const Icon(
                      Icons.flag,
                      color: Colors.red,
                      size: 40,
                    ),
                  ),
                // Marcadores de alertas cercanas
                ..._alertasCercanas.map((alerta) => Marker(
                  width: 50.0,
                  height: 50.0,
                  point: LatLng(
                    alerta.coords['lat']!,
                    alerta.coords['lng']!,
                  ),
                  builder: (ctx) => GestureDetector(
                    onTap: () {
                      _mostrarDetalleAlerta(alerta);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: _getColorTipoAlerta(alerta.tipo),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: Icon(
                        _getIconoTipoAlerta(alerta.tipo),
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                )),
              ],
            ),
          ],
        ),
        // Controles del mapa
        Positioned(
          right: 16,
          bottom: 150,
          child: Column(
            children: [
              FloatingActionButton(
                mini: true,
                heroTag: 'zoom_in_home',
                onPressed: () {
                  _mapController.move(
                    _mapController.center,
                    _mapController.zoom + 1.0,
                  );
                },
                child: const Icon(Icons.add),
                tooltip: 'Acercar',
              ),
              const SizedBox(height: 8),
              FloatingActionButton(
                mini: true,
                heroTag: 'zoom_out_home',
                onPressed: () {
                  _mapController.move(
                    _mapController.center,
                    _mapController.zoom - 1.0,
                  );
                },
                child: const Icon(Icons.remove),
                tooltip: 'Alejar',
              ),
              const SizedBox(height: 8),
              FloatingActionButton(
                mini: true,
                heroTag: 'my_location_home',
                onPressed: _toggleFollowUser,
                backgroundColor: _isFollowingUser ? Colors.blue : Colors.grey,
                child: const Icon(Icons.my_location),
                tooltip: 'Mi ubicación',
              ),
            ],
          ),
        ),
        
        // Banner de viaje activo (si existe) - solo en pantalla de inicio
        if (_viajeActivo != null && _selectedIndex == 0)
          Positioned(
            top: 16,
            left: 0,
            right: 0,
            child: ViajeActivoBanner(
              viajeActivo: _viajeActivo!,
              onIniciarViaje: () async {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => RutaViajeScreen(oportunidad: _viajeActivo!),
                  ),
                ).then((_) {
                  // Recargar viaje activo al volver
                  _cargarViajeActivo();
                });
              },
              onVerRuta: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => RutaViajeScreen(oportunidad: _viajeActivo!),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildRouteInfo() {
    // Calcular distancia aproximada en km
    final distance = calculateDistance(_currentPosition!, _destinoPosition!).round();
    
    return Positioned(
      left: 16,
      right: 16,
      bottom: 100,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Icon(Icons.location_on, color: Colors.red),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Destino: Pasto, Nariño',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$distance km',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Dirección: Calle 20 # 15-30, Centro, Pasto',
                style: TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  // Obtener color según tipo de alerta
  Color _getColorTipoAlerta(String tipo) {
    switch (tipo) {
      case 'trancon':
        return Colors.orange;
      case 'obstaculo':
        return Colors.yellow.shade700;
      case 'sospecha':
      case 'intento_robo':
        return Colors.red;
      case 'policia':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  // Obtener icono según tipo de alerta
  IconData _getIconoTipoAlerta(String tipo) {
    switch (tipo) {
      case 'trancon':
        return Icons.traffic; // 🚗 Tráfico
      case 'sospecha':
        return Icons.remove_red_eye; // 👁️ Actividad sospechosa
      case 'intento_robo':
        return Icons.warning; // ⚠️ Intento de robo
      case 'robo':
        return Icons.dangerous; // ❄️ Robo
      case 'obstaculo':
        return Icons.report_problem; // 🛑 Obstáculo
      case 'clima_adverso':
        return Icons.cloud; // ☁️ Clima adverso
      case 'accidente':
        return Icons.car_crash; // 🚗💥 Accidente
      case 'policia':
      case 'control_policial':
        return Icons.local_police; // 🚪 Control policial
      default:
        return Icons.info; // ℹ️ Otro
    }
  }

  // Mostrar detalle de alerta
  void _mostrarDetalleAlerta(AlertaSeguridad alerta) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(alerta.tipo.toUpperCase()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(alerta.descripcion ?? 'Sin descripción'),
            const SizedBox(height: 8),
            Text(
              'Hace ${_calcularTiempoTranscurrido(alerta.timestamp)}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
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

  // Calcular tiempo transcurrido
  String _calcularTiempoTranscurrido(DateTime timestamp) {
    final diferencia = DateTime.now().difference(timestamp);
    if (diferencia.inMinutes < 60) {
      return '${diferencia.inMinutes} min';
    } else if (diferencia.inHours < 24) {
      return '${diferencia.inHours} h';
    } else {
      return '${diferencia.inDays} d';
    }
  }

  Widget _buildStatusPanel() {
    // Verificar si hay viaje activo
    final bool tieneOportunidadActiva = _viajeActivo != null;
    final bool enRuta = _viajeActivo?.estado == 'en_ruta';
    
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(25),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                              color: enRuta ? Colors.green : (tieneOportunidadActiva ? Colors.orange : (_isDisponible ? Colors.blue : Colors.grey)),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              enRuta ? 'En ruta' : (tieneOportunidadActiva ? 'Viaje asignado' : (_isDisponible ? 'Disponible' : 'No disponible')),
                              style: const TextStyle(color: Colors.white, fontSize: 12),
                            ),
                          ),
                          if (!tieneOportunidadActiva) ...[
                            const SizedBox(width: 8),
                            Switch(
                              value: _isDisponible,
                              onChanged: (value) async {
                                setState(() {
                                  _isDisponible = value;
                                });
                                final authService = Provider.of<AuthService>(context, listen: false);
                                await authService.guardarEstadoDisponible(value);
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        value ? 'Ahora estás disponible para oportunidades' : 'Marcado como no disponible'
                                      ),
                                      duration: const Duration(seconds: 2),
                                    ),
                                  );
                                }
                              },
                              activeColor: Colors.blue,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        tieneOportunidadActiva 
                          ? (_viajeActivo!.origen + ' → ' + _viajeActivo!.destino)
                          : 'Sin viaje asignado',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    _showAlertDialog(context);
                  },
                  child: const Text('Alertar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  void _showAlertDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Reportar problema'),
          content: const Text('¿Deseas reportar un problema en tu ruta?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  _selectedIndex = 2; // Cambiar a pantalla de alertas
                });
              },
              child: const Text('Ir a Alertas'),
            ),
          ],
        );
      },
    );
  }
  
  double calculateDistance(LatLng point1, LatLng point2) {
    // Cálculo simple de distancia en kilómetros usando la fórmula de Haversine
    const R = 6371.0; // Radio de la Tierra en km
    
    final lat1Rad = point1.latitude * (math.pi / 180);
    final lat2Rad = point2.latitude * (math.pi / 180);
    final dLat = (point2.latitude - point1.latitude) * (math.pi / 180);
    final dLon = (point2.longitude - point1.longitude) * (math.pi / 180);
    
    final a = math.sin(dLat/2) * math.sin(dLat/2) +
              math.cos(lat1Rad) * math.cos(lat2Rad) * 
              math.sin(dLon/2) * math.sin(dLon/2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1-a));
    
    return R * c;
  }

  // Método para construir la lista de oportunidades
  Widget _buildOportunidadesList() {
    return const OportunidadesScreen();
  }

  // Método para construir la lista de alertas
  Widget _buildAlertas() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Encabezado con botón para crear nueva alerta
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Alertas de seguridad',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context, 
                    MaterialPageRoute(
                      builder: (context) => const AlertasScreen(),
                    ),
                  ).then((_) => {
                    // Recargar datos cuando regresa
                  });
                },
                icon: const Icon(Icons.add_alert),
                label: const Text('Crear alerta'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
        
        // Lista de alertas (vacía por ahora)
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.notification_important,
                        size: 64,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No hay alertas activas',
                        style: TextStyle(fontSize: 18),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Usa el botón "Alertar" para reportar problemas',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                      const SizedBox(height: 24),
                      OutlinedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context, 
                            MaterialPageRoute(
                              builder: (context) => const AlertasScreen(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.warning),
                        label: const Text('Ver todas las alertas'),
                      ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }
} 