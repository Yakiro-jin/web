class User {
  final String id;
  final String cedula;
  final String password;

  User({
    required this.id,
    required this.cedula,
    required this.password,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'cedula': cedula,
      'password': password,
    };
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      cedula: json['cedula'] as String? ?? json['email'] as String? ?? '',
      password: json['password'] as String,
    );
  }
}
