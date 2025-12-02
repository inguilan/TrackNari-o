// Código para reemplazar el método _iniciarViaje en ruta_viaje_screen.dart

Future<void> _iniciarViaje() async {
  try {
    // Mostrar diálogo de confirmación con detalles del viaje
    final confirmar = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
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
            _buildDetailRow(Icons.route, 'Distancia', '${_distanciaKm?.toStringAsFixed(1) ?? '0'} km'),
            _buildDetailRow(Icons.access_time, 'Duración', _duracionTexto ?? '0 min'),
            _buildDetailRow(Icons.location_on, 'Destino', widget.oportunidad.destino),
            _buildDetailRow(Icons.attach_money, 'Pago', '\$${widget.oportunidad.precio.toStringAsFixed(0)}'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: Colors.orange),
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
        final locationService = Provider.of<LocationService>(context, listen: false);
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
