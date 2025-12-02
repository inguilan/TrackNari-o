class User {
  final String? id;
  final String nombre;
  final String correo;
  final String? telefono;
  final String tipoUsuario;
  final String? empresa;
  final String? empresaAfiliada;
  final String? numeroCedula;
  final Map<String, dynamic>? camion;
  final String? metodoPago;
  final bool isDisponible;
  final double? calificacion;
  final int? viajesCompletados;
  final String? estadoAprobacion;
  final List<String>? camionerosAfiliados;
  final bool? disponibleParaSolicitarCamioneros;

  User({
    this.id,
    required this.nombre,
    required this.correo,
    this.telefono,
    required this.tipoUsuario,
    this.empresa,
    this.empresaAfiliada,
    this.numeroCedula,
    this.camion,
    this.metodoPago,
    this.isDisponible = false,
    this.calificacion,
    this.viajesCompletados,
    this.estadoAprobacion,
    this.camionerosAfiliados,
    this.disponibleParaSolicitarCamioneros,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id'] ?? json['id'],
      nombre: json['nombre'] ?? '',
      correo: json['correo'] ?? '',
      telefono: json['telefono'],
      tipoUsuario: json['tipoUsuario'] ?? '',
      empresa: json['empresa'],
      empresaAfiliada: json['empresaAfiliada'],
      numeroCedula: json['numeroCedula'],
      camion:
          json['camion'] != null
              ? Map<String, dynamic>.from(json['camion'])
              : null,
      metodoPago: json['metodoPago'],
      isDisponible: json['isDisponible'] ?? false,
      calificacion: json['calificacion']?.toDouble(),
      viajesCompletados: json['viajesCompletados'],
      estadoAprobacion: json['estadoAprobacion'] ?? 'pendiente',
      camionerosAfiliados:
          json['camionerosAfiliados'] != null
              ? List<String>.from(json['camionerosAfiliados'])
              : null,
      disponibleParaSolicitarCamioneros:
          json['disponibleParaSolicitarCamioneros'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'nombre': nombre,
      'correo': correo,
      if (telefono != null) 'telefono': telefono,
      'tipoUsuario': tipoUsuario,
      if (empresa != null) 'empresa': empresa,
      if (empresaAfiliada != null) 'empresaAfiliada': empresaAfiliada,
      if (numeroCedula != null) 'numeroCedula': numeroCedula,
      if (camion != null) 'camion': camion,
      if (metodoPago != null) 'metodoPago': metodoPago,
      'isDisponible': isDisponible,
      if (calificacion != null) 'calificacion': calificacion,
      if (viajesCompletados != null) 'viajesCompletados': viajesCompletados,
      if (estadoAprobacion != null) 'estadoAprobacion': estadoAprobacion,
      if (camionerosAfiliados != null)
        'camionerosAfiliados': camionerosAfiliados,
      if (disponibleParaSolicitarCamioneros != null)
        'disponibleParaSolicitarCamioneros': disponibleParaSolicitarCamioneros,
    };
  }

  User copyWith({
    String? nombre,
    String? telefono,
    String? empresa,
    String? metodoPago,
    Map<String, dynamic>? camion,
    bool? isDisponible,
    double? calificacion,
    int? viajesCompletados,
    String? estadoAprobacion,
    List<String>? camionerosAfiliados,
    bool? disponibleParaSolicitarCamioneros,
  }) {
    return User(
      id: id,
      nombre: nombre ?? this.nombre,
      correo: correo,
      telefono: telefono ?? this.telefono,
      tipoUsuario: tipoUsuario,
      empresa: empresa ?? this.empresa,
      empresaAfiliada: empresaAfiliada,
      numeroCedula: numeroCedula,
      camion: camion ?? this.camion,
      metodoPago: metodoPago ?? this.metodoPago,
      isDisponible: isDisponible ?? this.isDisponible,
      calificacion: calificacion ?? this.calificacion,
      viajesCompletados: viajesCompletados ?? this.viajesCompletados,
      estadoAprobacion: estadoAprobacion ?? this.estadoAprobacion,
      camionerosAfiliados: camionerosAfiliados ?? this.camionerosAfiliados,
      disponibleParaSolicitarCamioneros:
          disponibleParaSolicitarCamioneros ??
          this.disponibleParaSolicitarCamioneros,
    );
  }
}
