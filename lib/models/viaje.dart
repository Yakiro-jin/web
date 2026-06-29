class Viaje {
  final int idViaje;
  final DateTime fechaInicio;
  final DateTime fechaFinal;
  final double lactitud;
  final double longitud;
  final int idUser;
  final String idVehiculo;
  final String idRuta;
  final int? incidenciaId;

  // Relaciones anidadas (opcionales, vienen del endpoint Obtener-viaje-Id)
  final String? usuarioUsername;
  final String? vehiculoPlaca;
  final String? rutaNumero;
  final String? rutaNombre;

  Viaje({
    required this.idViaje,
    required this.fechaInicio,
    required this.fechaFinal,
    required this.lactitud,
    required this.longitud,
    required this.idUser,
    required this.idVehiculo,
    required this.idRuta,
    this.incidenciaId,
    this.usuarioUsername,
    this.vehiculoPlaca,
    this.rutaNumero,
    this.rutaNombre,
  });

  /// Factory para parsear la lista de viajes en curso
  /// Response: { "id_viaje": 1, "fecha_inicio": "...", "fecha_final": "...", "lactitud": ..., "longitud": ... }
  factory Viaje.fromJson(Map<String, dynamic> json) {
    // Nested objects (present in Obtener-viaje-Id)
    String? usuarioUsername;
    if (json['usuario'] != null && json['usuario'] is Map) {
      usuarioUsername = json['usuario']['username'] as String?;
    }

    String? vehiculoPlaca;
    if (json['vehiculo'] != null && json['vehiculo'] is Map) {
      vehiculoPlaca = json['vehiculo']['placa'] as String?;
    }

    String? rutaNumero;
    String? rutaNombre;
    if (json['ruta'] != null && json['ruta'] is Map) {
      rutaNumero = json['ruta']['numero_ruta'] as String?;
      rutaNombre = json['ruta']['nombre'] as String?;
    }

    return Viaje(
      idViaje: (json['id_viaje'] ?? 0) as int,
      fechaInicio: json['fecha_inicio'] != null
          ? DateTime.parse(json['fecha_inicio'] as String)
          : DateTime.now(),
      fechaFinal: json['fecha_final'] != null
          ? DateTime.parse(json['fecha_final'] as String)
          : DateTime.now().add(const Duration(days: 36159)), // ~99 años
      lactitud: ((json['lactitud'] ?? 0.0) as num).toDouble(),
      longitud: ((json['longitud'] ?? 0.0) as num).toDouble(),
      idUser: (json['id_user'] ?? 1) as int,
      idVehiculo: (json['id_vehiculo'] ?? json['vehiculo']?['placa'] ?? '') as String,
      idRuta: (json['id_ruta'] ?? json['ruta']?['numero_ruta'] ?? '') as String,
      incidenciaId: json['incidencia_id'] as int?,
      usuarioUsername: usuarioUsername,
      vehiculoPlaca: vehiculoPlaca,
      rutaNumero: rutaNumero,
      rutaNombre: rutaNombre,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fecha_inicio': fechaInicio.toIso8601String(),
      'fecha_final': fechaFinal.toIso8601String(),
      'lactitud': lactitud,
      'longitud': longitud,
      'id_user': idUser,
      'id_vehiculo': idVehiculo,
      'id_ruta': idRuta,
      'incidencia_id': incidenciaId,
    };
  }
}
