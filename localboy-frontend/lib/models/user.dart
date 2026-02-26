class User {
  final String id;
  final String phone;
  final String? name;
  final String? email;
  final String role;

  User({
    required this.id,
    required this.phone,
    this.name,
    this.email,
    required this.role,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      phone: json['phone'],
      name: json['name'],
      email: json['email'],
      role: json['role'] ?? 'tourist',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'phone': phone,
      'name': name,
      'email': email,
      'role': role,
    };
  }
}