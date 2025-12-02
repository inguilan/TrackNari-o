import 'package:flutter/material.dart';
import '../../models/oportunidad_model.dart';
import '../../services/oportunidad_service.dart';
import 'ruta_viaje_screen.dart';

class OportunidadesScreen extends StatefulWidget {
  const OportunidadesScreen({super.key});

  @override
  State<OportunidadesScreen> createState() => _OportunidadesScreenState();
}

class _OportunidadesScreenState extends State<OportunidadesScreen> {
  List<Oportunidad> _oportunidades = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _cargarOportunidades();
  }

  Future<void> _cargarOportunidades() async {
    print('🔄 Cargando oportunidades...');
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    
    try {
      final oportunidades = await OportunidadService.obtenerOportunidadesDisponibles();
      print('✅ Oportunidades cargadas: ${oportunidades.length}');
      if (mounted) {
        setState(() {
          _oportunidades = oportunidades;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Error al cargar oportunidades: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Error al cargar oportunidades: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _cargarOportunidades,
        child: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty 
            ? Center(child: Text(_errorMessage))
            : _oportunidades.isEmpty 
              ? _buildEmptyState() 
              : _buildOportunidadesList(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.local_shipping_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          const Text(
            'No hay oportunidades disponibles',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Vuelve más tarde para ver nuevas cargas',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: _cargarOportunidades,
            icon: const Icon(Icons.refresh),
            label: const Text('Actualizar'),
          ),
        ],
      ),
    );
  }

  Widget _buildOportunidadesList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _oportunidades.length,
      itemBuilder: (context, index) {
        final oportunidad = _oportunidades[index];
        return _buildOportunidadCard(oportunidad);
      },
    );
  }

  Widget _buildOportunidadCard(Oportunidad oportunidad) {
    // Calcular distancia y duración estimada (para simular como en Uber)
    final distanciaKm = (10 + oportunidad.titulo.length) % 100;  // Simulado
    final duracionMinutos = distanciaKm * 2;  // Simulado
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Cabecera con título y precio
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    oportunidad.titulo,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '\$${oportunidad.precio.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Cuerpo de la tarjeta
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Origen y destino
                _buildRouteInfo(oportunidad),
                
                const Divider(height: 24),
                
                // Información adicional
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildInfoItem(
                      Icons.route, 
                      '$distanciaKm km', 
                      'Distancia'
                    ),
                    _buildInfoItem(
                      Icons.timer, 
                      '~$duracionMinutos min', 
                      'Duración est.'
                    ),
                    _buildInfoItem(
                      Icons.calendar_today, 
                      _formatDate(oportunidad.fecha),
                      'Fecha'
                    ),
                  ],
                ),
                
                if (oportunidad.descripcion != null && oportunidad.descripcion!.isNotEmpty) ...[
                  const Divider(height: 24),
                  Text(
                    oportunidad.descripcion!,
                    style: TextStyle(
                      color: Colors.grey[700],
                    ),
                  ),
                ],
                const Divider(height: 24),
                // Botón para aceptar la carga
                ElevatedButton(
                  onPressed: () => _aceptarCarga(oportunidad),
                  child: const Text('Aceptar Carga'),
                ),
              ],
            ),
          ),
          
          // Botón de acción
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                // Mostrar detalles o realizar solicitud
                _mostrarDetallesOportunidad(oportunidad);
              },
              child: const Text('Ver detalles'),
            ),
          ),
          
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildRouteInfo(Oportunidad oportunidad) {
    return Row(
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
                oportunidad.origen,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 30),
              Text(
                oportunidad.destino,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}';
  }

  void _mostrarDetallesOportunidad(Oportunidad oportunidad) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    oportunidad.titulo,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              _buildRouteInfo(oportunidad),
              
              const SizedBox(height: 16),
              
              Text(
                'Precio: \$${oportunidad.precio.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              
              const SizedBox(height: 8),
              
              Text(
                'Fecha: ${oportunidad.fecha.day}/${oportunidad.fecha.month}/${oportunidad.fecha.year}',
              ),
              
              if (oportunidad.descripcion != null && oportunidad.descripcion!.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text(
                  'Descripción:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(oportunidad.descripcion!),
              ],
              
              const SizedBox(height: 24),
              
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: () {
                    // Aquí iría la lógica para solicitar esta oportunidad
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Solicitud enviada')),
                    );
                  },
                  child: const Text(
                    'SOLICITAR ESTA CARGA',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Función para aceptar una carga
  Future<void> _aceptarCarga(Oportunidad oportunidad) async {
    // Mostrar diálogo de confirmación
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Aceptar carga'),
        content: Text('¿Estás seguro de que deseas aceptar la carga de ${oportunidad.origen} a ${oportunidad.destino}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Aceptar'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    try {
      // Mostrar indicador de carga
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // Aceptar la carga en el backend
      final oportunidadAceptada = await OportunidadService.aceptarOportunidad(oportunidad.id!);
      
      // Cerrar indicador de carga
      if (!mounted) return;
      Navigator.pop(context);

      // Mostrar mensaje de éxito
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Carga aceptada exitosamente'),
          backgroundColor: Colors.green,
        ),
      );

      // Navegar a la pantalla de ruta
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => RutaViajeScreen(oportunidad: oportunidadAceptada),
        ),
      );

      // Recargar oportunidades para eliminar la que fue aceptada
      _cargarOportunidades();
    } catch (e) {
      // Cerrar indicador de carga si está abierto
      if (!mounted) return;
      Navigator.pop(context);

      // Mostrar error
      String mensaje = 'Error al aceptar carga';
      if (e.toString().contains('Ya tienes un viaje activo')) {
        mensaje = 'Ya tienes un viaje activo. Finaliza tu viaje actual antes de aceptar otra carga.';
      } else if (e.toString().contains('ya fue aceptada')) {
        mensaje = 'Esta oportunidad ya fue aceptada por otro camionero.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(mensaje),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
} 