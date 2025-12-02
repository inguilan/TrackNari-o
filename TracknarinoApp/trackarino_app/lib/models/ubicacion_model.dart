class Ubicacion {
  final String? id;
  final String camionero;
  final Map<String, double> coords;
  final DateTime timestamp;
  final double? velocidad;
  final double? precision;
  final double? rumbo;

  Ubicacion({
    this.id,
    required this.camionero,
    required this.coords,
    required this.timestamp,
    this.velocidad,
    this.precision,
    this.rumbo,
  });

  factory Ubicacion.fromJson(Map<String, dynamic> json) {
    return Ubicacion(
      id: json['_id'],
      camionero: json['camionero'],
      coords: {
        'lat': json['coords']['lat'].toDouble(),
        'lng': json['coords']['lng'].toDouble(),
      },
      timestamp: DateTime.parse(json['timestamp']),
      velocidad: json['velocidad']?.toDouble(),
      precision: json['precision']?.toDouble(),
      rumbo: json['rumbo']?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'camionero': camionero,
      'coords': coords,
      'timestamp': timestamp.toIso8601String(),
      if (velocidad != null) 'velocidad': velocidad,
      if (precision != null) 'precision': precision,
      if (rumbo != null) 'rumbo': rumbo,
    };
  }
} 