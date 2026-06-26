class SystemUser {
  final String id;
  final String nombre;
  final String apellido;
  final String cedula;
  final String rol;
  final String correo;
  final String password;

  SystemUser({
    required this.id,
    required this.nombre,
    required this.apellido,
    required this.cedula,
    required this.rol,
    required this.correo,
    required this.password,
  });

  SystemUser copyWith({
    String? id,
    String? nombre,
    String? apellido,
    String? cedula,
    String? rol,
    String? correo,
    String? password,
  }) {
    return SystemUser(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      apellido: apellido ?? this.apellido,
      cedula: cedula ?? this.cedula,
      rol: rol ?? this.rol,
      correo: correo ?? this.correo,
      password: password ?? this.password,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'apellido': apellido,
      'cedula': cedula,
      'rol': rol,
      'correo': correo,
      'password': password,
    };
  }

  factory SystemUser.fromJson(Map<String, dynamic> json) {
    return SystemUser(
      id: json['id'] as String? ?? '',
      nombre: json['nombre'] as String? ?? '',
      apellido: json['apellido'] as String? ?? '',
      cedula: json['cedula'] as String? ?? '',
      rol: json['rol'] as String? ?? '',
      correo: json['correo'] as String? ?? '',
      password: json['password'] as String? ?? '',
    );
  }
}
