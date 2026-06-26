class Cooperative {
  final String id; // maps to rif_cooperativa
  final String name; // maps to nombre
  final String description; // maps to descripcion
  final String location; // maps to ubicacion
  final String schedule; // maps to horario
  final DateTime createdAt;

  Cooperative({
    required this.id,
    required this.name,
    required this.description,
    required this.location,
    required this.schedule,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'rif_cooperativa': id,
      'nombre': name,
      'descripcion': description,
      'ubicacion': location,
      'horario': schedule,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Cooperative.fromJson(Map<String, dynamic> json) {
    return Cooperative(
      id: (json['rif_cooperativa'] ?? json['id'] ?? '') as String,
      name: (json['nombre'] ?? json['name'] ?? '') as String,
      description: (json['descripcion'] ?? json['description'] ?? '') as String,
      location: (json['ubicacion'] ?? json['location'] ?? '') as String,
      schedule: (json['horario'] ?? json['schedule'] ?? '') as String,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
    );
  }

  Cooperative copyWith({
    String? id,
    String? name,
    String? description,
    String? location,
    String? schedule,
    DateTime? createdAt,
  }) {
    return Cooperative(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      location: location ?? this.location,
      schedule: schedule ?? this.schedule,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
