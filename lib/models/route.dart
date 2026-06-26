class RouteStop {
  final String name;
  final double latitude;
  final double longitude;

  RouteStop({
    required this.name,
    required this.latitude,
    required this.longitude,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  factory RouteStop.fromJson(Map<String, dynamic> json) {
    return RouteStop(
      name: (json['nombre'] ?? json['name'] ?? '') as String,
      latitude: ((json['lactitud'] ?? json['latitude'] ?? 0.0) as num).toDouble(),
      longitude: ((json['longitud'] ?? json['longitude'] ?? 0.0) as num).toDouble(),
    );
  }
}

class TransportRoute {
  final String id; // maps to numero_ruta
  final String name; // maps to nombre
  final String description; // maps to descripcion
  final int fare; // maps to tarifa
  final String origin; // maps to origin name
  final String destination; // maps to destination name
  final int? originId; // maps to origen_id
  final int? destinationId; // maps to destino_id
  final String cooperativeId; // maps to cooperativa_id
  final List<RouteStop> stops;
  final DateTime createdAt;

  TransportRoute({
    required this.id,
    required this.name,
    required this.description,
    required this.fare,
    required this.origin,
    required this.destination,
    this.originId,
    this.destinationId,
    required this.cooperativeId,
    required this.stops,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'numero_ruta': id,
      'nombre': name,
      'descripcion': description,
      'tarifa': fare,
      'cooperativa_id': cooperativeId,
      'origen_id': originId,
      'destino_id': destinationId,
      'stops': stops.map((s) => s.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory TransportRoute.fromJson(Map<String, dynamic> json) {
    // Determine cooperative ID
    String coopId = '';
    if (json['cooperativa'] != null && json['cooperativa'] is Map) {
      coopId = (json['cooperativa']['rif_cooperativa'] ?? json['cooperativa']['id'] ?? '') as String;
    } else {
      coopId = (json['cooperativa_id'] ?? json['cooperativeId'] ?? '') as String;
    }

    // Determine origin name and destination name
    String originName = 'Origen';
    if (json['origen'] != null && json['origen'] is Map) {
      originName = (json['origen']['nombre'] ?? json['origen']['name'] ?? 'Origen') as String;
    } else {
      originName = (json['origin'] ?? 'Origen') as String;
    }

    String destName = 'Destino';
    if (json['destino'] != null && json['destino'] is Map) {
      destName = (json['destino']['nombre'] ?? json['destino']['name'] ?? 'Destino') as String;
    } else {
      destName = (json['destination'] ?? 'Destino') as String;
    }

    return TransportRoute(
      id: (json['numero_ruta'] ?? json['id'] ?? '') as String,
      name: (json['nombre'] ?? json['name'] ?? '') as String,
      description: (json['descripcion'] ?? '') as String,
      fare: (json['tarifa'] ?? json['fare'] ?? 0) as int,
      origin: originName,
      destination: destName,
      originId: json['origen_id'] as int?,
      destinationId: json['destino_id'] as int?,
      cooperativeId: coopId,
      stops: (json['stops'] as List? ?? [])
          .map((s) => RouteStop.fromJson(s as Map<String, dynamic>))
          .toList(),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
    );
  }

  TransportRoute copyWith({
    String? id,
    String? name,
    String? description,
    int? fare,
    String? origin,
    String? destination,
    int? originId,
    int? destinationId,
    String? cooperativeId,
    List<RouteStop>? stops,
    DateTime? createdAt,
  }) {
    return TransportRoute(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      fare: fare ?? this.fare,
      origin: origin ?? this.origin,
      destination: destination ?? this.destination,
      originId: originId ?? this.originId,
      destinationId: destinationId ?? this.destinationId,
      cooperativeId: cooperativeId ?? this.cooperativeId,
      stops: stops ?? this.stops,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
