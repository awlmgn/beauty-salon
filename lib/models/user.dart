// models/user.dart

class User {
  final int id;
  final String email;
  final String name;
  final String? phone;
  final DateTime? createdAt;

  User({
    required this.id,
    required this.email,
    required this.name,
    this.phone,
    this.createdAt,
  });

  factory User.empty() {
    return User(
      id: 0,
      email: '',
      name: 'Гость',
    );
  }

  User copyWith({
    int? id,
    String? email,
    String? name,
    String? phone,
    DateTime? createdAt,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // ЗАМЕНИ ЭТОТ МЕТОД:
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: (json['id'] as num).toInt(),
      email: json['email'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String?,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'phone': phone,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'User(id: $id, email: $email, name: $name)';
  }
}