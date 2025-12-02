class Oportunidad {
  final String? id;
  final String titulo;
  final String? descripcion;
  final String origen;
  final String destino;
  final String? direccionCargue;
  final String? direccionDescargue;
  final DateTime fecha;
  final double precio;
  final String estado;
  final bool finalizada;
  final String contratista;
  final String? camioneroAsignado;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int? pesoCarga; // Peso en toneladas
  final String? tipoCarga;
  final String? requisitosEspeciales;
  final int? distanciaKm;
  final int? duracionEstimadaHoras;

  Oportunidad({
    this.id,
    required this.titulo,
    this.descripcion,
    required this.origen,
    required this.destino,
    this.direccionCargue,
    this.direccionDescargue,
    required this.fecha,
    required this.precio,
    required this.estado,
    required this.finalizada,
    required this.contratista,
    this.camioneroAsignado,
    this.createdAt,
    this.updatedAt,
    this.pesoCarga,
    this.tipoCarga,
    this.requisitosEspeciales,
    this.distanciaKm,
    this.duracionEstimadaHoras,
  });

  factory Oportunidad.fromJson(Map<String, dynamic> json) {
    // Extraer contratista (puede ser String o Map)
    String contratistaId;
    if (json['contratista'] is String) {
      contratistaId = json['contratista'];
    } else if (json['contratista'] is Map) {
      contratistaId = json['contratista']['_id'] ?? json['contratista']['id'] ?? 'desconocido';
    } else {
      contratistaId = 'desconocido';
    }

    // Extraer camioneroAsignado (puede ser String, Map o null)
    String? camioneroId;
    if (json['camioneroAsignado'] == null) {
      camioneroId = null;
    } else if (json['camioneroAsignado'] is String) {
      camioneroId = json['camioneroAsignado'];
    } else if (json['camioneroAsignado'] is Map) {
      camioneroId = json['camioneroAsignado']['_id'] ?? json['camioneroAsignado']['id'];
    }

    return Oportunidad(
      id: json['_id'],
      titulo: json['titulo'],
      descripcion: json['descripcion'],
      origen: json['origen'],
      destino: json['destino'],
      direccionCargue: json['direccionCargue'],
      direccionDescargue: json['direccionDescargue'],
      fecha: DateTime.parse(json['fecha']),
      precio: (json['precio'] as num).toDouble(),
      estado: json['estado'] ?? 'disponible',
      finalizada: json['finalizada'] ?? false,
      contratista: contratistaId,
      camioneroAsignado: camioneroId,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
      pesoCarga: json['pesoCarga'],
      tipoCarga: json['tipoCarga'],
      requisitosEspeciales: json['requisitosEspeciales'],
      distanciaKm: json['distanciaKm'],
      duracionEstimadaHoras: json['duracionEstimadaHoras'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'titulo': titulo,
      'descripcion': descripcion,
      'origen': origen,
      'destino': destino,
      'direccionCargue': direccionCargue,
      'direccionDescargue': direccionDescargue,
      'fecha': fecha.toIso8601String(),
      'precio': precio,
      'estado': estado,
      'finalizada': finalizada,
      'contratista': contratista,
      'camioneroAsignado': camioneroAsignado,
      if (pesoCarga != null) 'pesoCarga': pesoCarga,
      if (tipoCarga != null) 'tipoCarga': tipoCarga,
      if (requisitosEspeciales != null) 'requisitosEspeciales': requisitosEspeciales,
      if (distanciaKm != null) 'distanciaKm': distanciaKm,
      if (duracionEstimadaHoras != null) 'duracionEstimadaHoras': duracionEstimadaHoras,
    };
  }
} 