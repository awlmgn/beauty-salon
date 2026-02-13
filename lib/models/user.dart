// models/user.dart

class User {
  final int id;
  final String email;
  final String? password;
  final String name;
  final String? phone;
  final DateTime? createdAt;

  User({
    required this.id,
    required this.email,
    this.password,
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
    String? password,
    String? name,
    String? phone,
    DateTime? createdAt,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      password: password ?? this.password,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: (json['id'] as num).toInt(),
      email: json['email'] as String? ?? '', // Запасное значение
      password: json['password'] as String?, // Может быть null
      name: json['name'] as String? ?? '', // Запасное значение
      phone: json['phone'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }


  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'password': password,
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

class Note {
  final int id;
  final String title;
  final String content;
  final DateTime createdAt;

  Note({
    required this.id,
    required this.title,
    required this.content,
    required this.createdAt,
  });

  Note copyWith({
    int? id,
    String? title,
    String? content,
    DateTime? createdAt,
  }) {
    return Note(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // Добавим полезные методы для Note
  factory Note.empty() {
    return Note(
      id: 0,
      title: '',
      content: '',
      createdAt: DateTime.now(),
    );
  }

  factory Note.fromJson(Map<String, dynamic> json) {
    return Note(
      id: (json['id'] as num?)?.toInt() ?? 0,
      title: json['title'] as String? ?? '',
      content: json['content'] as String? ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'created_at': createdAt.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'Note(id: $id, title: $title)';
  }
}