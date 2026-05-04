class AppUser {
  final String id;
  final String? phone;
  final String? email;
  final String? name;
  final DateTime? dob;
  final String? avatarUrl;
  final String role;
  final bool isPhoneVerified;
  final bool isEmailVerified;
  final bool isProfileComplete;

  AppUser({
    required this.id,
    this.phone,
    this.email,
    this.name,
    this.dob,
    this.avatarUrl,
    required this.role,
    required this.isPhoneVerified,
    required this.isEmailVerified,
    required this.isProfileComplete,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'],
      phone: json['phone'],
      email: json['email'],
      name: json['name'],
      dob: json['dob'] != null ? DateTime.tryParse(json['dob'].toString()) : null,
      avatarUrl: json['avatar_url'],
      role: json['role'] ?? 'tourist',
      isPhoneVerified: json['is_phone_verified'] ?? false,
      isEmailVerified: json['is_email_verified'] ?? false,
      isProfileComplete: json['is_profile_complete'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'phone': phone,
      'email': email,
      'name': name,
      'dob': dob?.toIso8601String(),
      'avatar_url': avatarUrl,
      'role': role,
      'is_phone_verified': isPhoneVerified,
      'is_email_verified': isEmailVerified,
      'is_profile_complete': isProfileComplete,
    };
  }
}