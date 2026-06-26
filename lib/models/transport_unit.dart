class TransportUnit {
  final String id; // maps to placa
  final String plate; // maps to placa
  final String model; // maps to modelo
  final String color; // maps to color
  final String yearOfManufacture; // maps to anofabricacion
  final String cooperativeId;
  final String? driverId;
  final String? routeId;
  final DateTime createdAt;

  TransportUnit({
    required this.id,
    required this.plate,
    required this.model,
    required this.color,
    required this.yearOfManufacture,
    required this.cooperativeId,
    this.driverId,
    this.routeId,
    required this.createdAt,
  });

  // Getter aliases for compatibility
  String get unitNumber => model;
  int get capacity => 0;

  Map<String, dynamic> toJson() {
    return {
      'placa': plate,
      'modelo': model,
      'color': color,
      'anofabricacion': yearOfManufacture,
      'cooperativa_id': cooperativeId,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory TransportUnit.fromJson(Map<String, dynamic> json) {
    String coopId = '';
    if (json['cooperativa'] != null && json['cooperativa'] is Map) {
      coopId = (json['cooperativa']['rif_cooperativa'] ?? json['cooperativa']['id'] ?? '') as String;
    } else {
      coopId = (json['cooperativa_id'] ?? json['cooperativeId'] ?? '') as String;
    }

    return TransportUnit(
      id: (json['placa'] ?? json['id'] ?? '') as String,
      plate: (json['placa'] ?? json['plate'] ?? '') as String,
      model: (json['modelo'] ?? json['model'] ?? json['unitNumber'] ?? '') as String,
      color: (json['color'] ?? '') as String,
      yearOfManufacture: (json['anofabricacion'] ?? json['yearOfManufacture'] ?? '') as String,
      cooperativeId: coopId,
      driverId: json['driverId'] as String?,
      routeId: json['routeId'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
    );
  }

  TransportUnit copyWith({
    String? id,
    String? plate,
    String? model,
    String? color,
    String? yearOfManufacture,
    String? cooperativeId,
    String? driverId,
    String? routeId,
    DateTime? createdAt,
  }) {
    return TransportUnit(
      id: id ?? this.id,
      plate: plate ?? this.plate,
      model: model ?? this.model,
      color: color ?? this.color,
      yearOfManufacture: yearOfManufacture ?? this.yearOfManufacture,
      cooperativeId: cooperativeId ?? this.cooperativeId,
      driverId: driverId ?? this.driverId,
      routeId: routeId ?? this.routeId,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
