import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/alerta_model.dart';
import '../services/alerta_service.dart';
import '../services/location_service.dart';
import 'package:provider/provider.dart';
import '../utils/flutter_map_fixes.dart';

class AlertasScreen extends StatefulWidget {
  const AlertasScreen({super.key});

  @override
  State<AlertasScreen> createState() => _AlertasScreenState();
}

class _AlertasScreenState extends State<AlertasScreen> with SingleTickerProviderStateMixin {
  List<AlertaSeguridad> _alertas = [];
  bool _isLoading = true;
  String _errorMessage = '';
  late TabController _tabController;
  String _selectedTipoAlerta = 'trancon';
  final TextEditingController _descripcionController = TextEditingController();
  bool _isSendingAlert = false;
  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;
  LatLng? _selectedLocation;
  bool _compartirConOtros = true;
  bool _verMapa = false;
  late MapController _mapController;

  final Map<String, Map<String, dynamic>> _tiposAlertas = {
    'trancon': {
      'titulo': 'Tráfico',
      'descripcion': 'Reportar un tráfico intenso o embotellamiento',
      'icono': Icons.traffic,
      'color': Colors.orange,
    },
    'sospecha': {
      'titulo': 'Actividad sospechosa',
      'descripcion': 'Reportar actividad sospechosa en la ruta',
      'icono': Icons.visibility,
      'color': Colors.amber,
    },
    'intento_robo': {
      'titulo': 'Intento de robo',
      'descripcion': 'Reportar un intento de robo',
      'icono': Icons.warning,
      'color': Colors.deepOrange,
    },
    'robo': {
      'titulo': 'Robo',
      'descripcion': 'Reportar un robo (emergencia)',
      'icono': Icons.emergency,
      'color': Colors.red,
    },
    'obstaculo': {
      'titulo': 'Obstáculo',
      'descripcion': 'Reportar un obstáculo en la carretera',
      'icono': Icons.warning_amber,
      'color': Colors.amber,
    },
    'clima': {
      'titulo': 'Clima adverso',
      'descripcion': 'Reportar condiciones climáticas adversas',
      'icono': Icons.cloud,
      'color': Colors.blue,
    },
    'accidente': {
      'titulo': 'Accidente',
      'descripcion': 'Reportar un accidente de tránsito',
      'icono': Icons.car_crash,
      'color': Colors.red,
    },
    'policia': {
      'titulo': 'Control policial',
      'descripcion': 'Reportar un control policial',
      'icono': Icons.local_police,
      'color': Colors.blue,
    },
    'otro': {
      'titulo': 'Otro',
      'descripcion': 'Reportar otro tipo de alerta',
      'icono': Icons.info,
      'color': Colors.grey,
    },
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _mapController = MapController();
    // Inicializamos la ubicación primero
    _cargarUbicacionActual().then((_) {
      // Luego cargamos las alertas una vez tengamos la ubicación
      _cargarAlertas();
    });
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    _descripcionController.dispose();
    super.dispose();
  }

  Future<void> _cargarAlertas() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    
    try {
      final position = await Provider.of<LocationService>(context, listen: false).getCurrentLocation();
      
      if (position != null) {
        final alertas = await AlertaService.obtenerAlertasCercanas(position);
        if (mounted) {
          setState(() {
            _alertas = alertas;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _errorMessage = 'No se pudo obtener tu ubicación actual';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error al cargar alertas: $e';
          _isLoading = false;
        });
      }
      debugPrint('Error cargando alertas: $e');
    }
  }
  
  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera, 
        maxWidth: 1024, // Reducir tamaño para evitar problemas de memoria
        maxHeight: 1024,
        imageQuality: 85 // Nivel de compresión
      );
      if (image != null && mounted) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      _mostrarError('No se pudo capturar la imagen: $e');
      debugPrint('Error al capturar imagen: $e');
    }
  }
  
  void _mostrarError(String mensaje) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: Colors.red.shade700,
      ),
    );
  }

  void _mostrarExito(String mensaje) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: Colors.green.shade700,
      ),
    );
  }
  
  void _toggleMapView() {
    setState(() {
      _verMapa = !_verMapa;
    });
  }
  
  void _onMapTap(LatLng position) {
    setState(() {
      _selectedLocation = position;
    });
  }
  
  Future<void> _crearAlerta() async {
    if (_selectedLocation == null) {
      _mostrarError('Selecciona una ubicación en el mapa');
      return;
    }
    
    setState(() {
      _isSendingAlert = true;
    });
    
    try {
      await AlertaService.crearAlerta(
        tipo: _selectedTipoAlerta,
        coords: {
          'lat': _selectedLocation!.latitude,
          'lng': _selectedLocation!.longitude,
        },
        descripcion: _descripcionController.text.isNotEmpty 
            ? _descripcionController.text 
            : null,
        imagePath: _selectedImage?.path,
        compartir: _compartirConOtros,
      );
      
      _descripcionController.clear();
      
      if (mounted) {
        setState(() {
          _selectedImage = null;
          _isSendingAlert = false;
        });
        
        _mostrarExito('Alerta creada con éxito');
        _cargarAlertas(); // Recargar alertas
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSendingAlert = false;
        });
        _mostrarError('Error al crear la alerta: $e');
        debugPrint('Error al crear alerta: $e');
      }
    }
  }

  Future<void> _cargarUbicacionActual() async {
    try {
      final position = await Provider.of<LocationService>(context, listen: false).getCurrentLocation();
      
      if (position != null && mounted) {
        setState(() {
          _selectedLocation = LatLng(position.latitude, position.longitude);
          debugPrint('Ubicación actual cargada: ${position.latitude}, ${position.longitude}');
        });
      }
    } catch (e) {
      debugPrint('Error al cargar ubicación inicial: $e');
      // Usar ubicación predeterminada (Pasto)
      if (mounted) {
        setState(() {
          _selectedLocation = LatLng(1.2136, -77.2811);
        });
      }
    }
  }

  void _centrarMapa() {
    if (_selectedLocation != null) {
      _mapController.move(_selectedLocation!, 15.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Alertas de Seguridad'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Ver Alertas'),
            Tab(text: 'Crear Alerta'),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(_verMapa ? Icons.list : Icons.map),
            onPressed: _toggleMapView,
            tooltip: _verMapa ? 'Ver lista' : 'Ver mapa',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarAlertas,
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Ver Alertas
          _buildAlertasTab(),
          
          // Tab 2: Crear Alerta
          _buildCrearAlertaTab(),
        ],
      ),
      floatingActionButton: _verMapa ? FloatingActionButton(
        onPressed: _centrarMapa,
        tooltip: 'Centrar mapa',
        child: const Icon(Icons.my_location),
      ) : null,
    );
  }
  
  Widget _buildAlertasTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _errorMessage,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _cargarAlertas,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }
    
    if (_alertas.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.info_outline, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('No hay alertas cercanas en este momento'),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _cargarAlertas,
              icon: const Icon(Icons.refresh),
              label: const Text('Actualizar'),
            ),
          ],
        ),
      );
    }
    
    if (_verMapa) {
      return _buildMapaAlertas();
    } else {
      return _buildListaAlertas();
    }
  }
  
  Widget _buildMapaAlertas() {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        center: _selectedLocation ?? LatLng(1.2136, -77.2811),
        zoom: 12.0,
        onTap: (_, point) => _onMapTap(point),
      ),
      children: [
        TileLayer(
          urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
          subdomains: const ['a', 'b', 'c'],
          userAgentPackageName: 'com.trackarino.app',
        ),
        MarkerLayer(
          markers: [
            // Marcador para ubicación actual
            if (_selectedLocation != null)
              Marker(
                point: _selectedLocation!,
                builder: (ctx) => const Icon(
                  Icons.my_location,
                  color: Colors.blue,
                  size: 30,
                ),
              ),
            
            // Marcadores para cada alerta
            ..._alertas.map((alerta) => Marker(
              point: LatLng(alerta.coords['lat']!, alerta.coords['lng']!),
              builder: (ctx) => Icon(
                _tiposAlertas[alerta.tipo]?['icono'] as IconData? ?? Icons.warning,
                color: _tiposAlertas[alerta.tipo]?['color'] as Color? ?? Colors.red,
                size: 30,
              ),
            )),
          ],
        ),
      ],
    );
  }
  
  Widget _buildListaAlertas() {
    return ListView.builder(
      itemCount: _alertas.length,
      itemBuilder: (context, index) {
        final alerta = _alertas[index];
        final tipoAlerta = _tiposAlertas[alerta.tipo];
        
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: (tipoAlerta?['color'] as Color? ?? Colors.grey).withAlpha(50),
              child: Icon(
                tipoAlerta?['icono'] as IconData? ?? Icons.warning,
                color: tipoAlerta?['color'] as Color? ?? Colors.grey,
              ),
            ),
            title: Text(tipoAlerta?['titulo'] as String? ?? 'Alerta'),
            subtitle: alerta.descripcion != null 
                ? Text(alerta.descripcion!) 
                : Text(tipoAlerta?['descripcion'] as String? ?? ''),
            trailing: Text(
              _formatTimeDifference(alerta.timestamp),
              style: const TextStyle(fontSize: 12),
            ),
            onTap: () {
              setState(() {
                _selectedLocation = LatLng(alerta.coords['lat']!, alerta.coords['lng']!);
                _verMapa = true;
              });
            },
          ),
        );
      },
    );
  }
  
  Widget _buildCrearAlertaTab() {
    final ubicacion = _selectedLocation ?? LatLng(1.2136, -77.2811);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Crear nueva alerta de seguridad',
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 16),
          
          const Text(
            'Selecciona una ubicación en el mapa, elige el tipo de alerta y añade una descripción opcional.',
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 16),
          
          Container(
            height: 200,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  center: ubicacion,
                  zoom: 15.0,
                  onTap: (_, point) => _onMapTap(point),
                ),
                children: [
                  TileLayer(
                    urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                    subdomains: const ['a', 'b', 'c'],
                    userAgentPackageName: 'com.trackarino.app',
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        width: 40.0,
                        height: 40.0,
                        point: ubicacion,
                        builder: (ctx) => const Icon(
                          Icons.location_on,
                          color: Colors.red,
                          size: 40,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          Text(
            'Ubicación seleccionada: ${_selectedLocation != null ? '${_selectedLocation!.latitude.toStringAsFixed(4)}, ${_selectedLocation!.longitude.toStringAsFixed(4)}' : 'Ninguna'}',
            style: const TextStyle(fontStyle: FontStyle.italic),
          ),
          
          const SizedBox(height: 16),
          
          Text('Tipo de alerta:', style: Theme.of(context).textTheme.titleMedium),
          
          const SizedBox(height: 8),
          
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _tiposAlertas.entries.map((entry) {
              return ChoiceChip(
                label: Text(entry.value['titulo'] as String),
                selected: _selectedTipoAlerta == entry.key,
                onSelected: (selected) {
                  if (selected) {
                    setState(() {
                      _selectedTipoAlerta = entry.key;
                    });
                  }
                },
                avatar: Icon(entry.value['icono'] as IconData),
                selectedColor: (entry.value['color'] as Color).withAlpha(50),
              );
            }).toList(),
          ),
          
          const SizedBox(height: 16),
          
          TextField(
            controller: _descripcionController,
            decoration: const InputDecoration(
              labelText: 'Descripción (opcional)',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Tomar foto'),
                ),
              ),
              if (_selectedImage != null) ...[
                const SizedBox(width: 16),
                Stack(
                  alignment: Alignment.topRight,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(_selectedImage!, fit: BoxFit.cover),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.cancel, color: Colors.red),
                      onPressed: () => setState(() => _selectedImage = null),
                      iconSize: 20,
                    ),
                  ],
                ),
              ],
            ],
          ),
          
          const SizedBox(height: 16),
          
          SwitchListTile(
            title: const Text('Compartir con otros camioneros'),
            value: _compartirConOtros,
            onChanged: (value) => setState(() => _compartirConOtros = value),
            subtitle: const Text('Permite que otros vean esta alerta'),
          ),
          
          const SizedBox(height: 24),
          
          ElevatedButton.icon(
            onPressed: _isSendingAlert ? null : _crearAlerta,
            icon: _isSendingAlert 
                ? const SizedBox(
                    width: 20, 
                    height: 20, 
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ) 
                : const Icon(Icons.send),
            label: Text(_isSendingAlert ? 'Enviando...' : 'Enviar Alerta'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ],
      ),
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
} 