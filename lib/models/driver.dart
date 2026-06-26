class Driver {
  final String id; // maps to cedula
  final String name; // maps to nombre
  final String lastName; // maps to apellido
  final String email;
  final String phone; // maps to telefono
  final int age; // maps to edad
  final String cooperativeId;
  final DateTime createdAt;

  Driver({
    required this.id,
    required this.name,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.age,
    required this.cooperativeId,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'cedula': id,
      'nombre': name,
      'apellido': lastName,
      'email': email,
      'telefono': phone,
      'edad': age,
      'cooperativeId': cooperativeId,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Driver.fromJson(Map<String, dynamic> json) {
    return Driver(
      id: (json['cedula'] ?? json['id'] ?? '').toString(),
      name: (json['nombre'] ?? json['name'] ?? '').toString(),
      lastName: (json['apellido'] ?? json['lastName'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      phone: (json['telefono'] ?? json['phone'] ?? '').toString(),
      age: json['edad'] is int
          ? json['edad'] as int
          : int.tryParse((json['edad'] ?? json['age'] ?? 0).toString()) ?? 0,
      cooperativeId: (json['cooperativeId'] ?? '').toString(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Driver copyWith({
    String? id,
    String? name,
    String? lastName,
    String? email,
    String? phone,
    int? age,
    String? cooperativeId,
    DateTime? createdAt,
  }) {
    return Driver(
      id: id ?? this.id,
      name: name ?? this.name,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      age: age ?? this.age,
      cooperativeId: cooperativeId ?? this.cooperativeId,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
