import 'package:flutter/material.dart';
import '../models/oportunidad_model.dart';
import '../screens/camionero/ruta_viaje_screen.dart';

class ViajeActivoBanner extends StatelessWidget {
  final Oportunidad viajeActivo;
  final VoidCallback onIniciarViaje;
  final VoidCallback onVerRuta;

  const ViajeActivoBanner({
    super.key,
    required this.viajeActivo,
    required this.onIniciarViaje,
    required this.onVerRuta,
  });

  @override
  Widget build(BuildContext context) {
    final esAsignado = viajeActivo.estado == 'asignada';
    final enRuta = viajeActivo.estado == 'en_ruta';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Cabecera compacta con estado
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: enRuta ? Colors.green : Colors.orange,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  enRuta ? Icons.local_shipping : Icons.assignment_turned_in,
                  color: Colors.white,
                  size: 18,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    enRuta ? '🚚 En curso' : '📦 Asignado',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
                if (!enRuta)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Pendiente',
                      style: TextStyle(
                        color: Colors.orange,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Información del viaje compacta
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  viajeActivo.titulo,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                
                // Ruta compacta (horizontal)
                Row(
                  children: [
                    const Icon(Icons.circle, color: Colors.green, size: 10),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        viajeActivo.origen,
                        style: const TextStyle(fontSize: 11),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4),
                      child: Icon(Icons.arrow_forward, size: 12, color: Colors.grey),
                    ),
                    Flexible(
                      child: Text(
                        viajeActivo.destino,
                        style: const TextStyle(fontSize: 11),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Icon(Icons.location_on, color: Colors.red, size: 10),
                  ],
                ),
                const SizedBox(height: 6),
                
                // Precio y botones en una línea
                Row(
                  children: [
                    Text(
                      '\$${viajeActivo.precio.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: onVerRuta,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          minimumSize: const Size(0, 28),
                        ),
                        child: const Text('Ver', style: TextStyle(fontSize: 11)),
                      ),
                    ),
                    if (esAsignado) ...[
                      const SizedBox(width: 6),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: onIniciarViaje,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            minimumSize: const Size(0, 28),
                          ),
                          child: const Text('Iniciar', style: TextStyle(fontSize: 11)),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
