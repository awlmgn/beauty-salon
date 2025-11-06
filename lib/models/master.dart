class Master {
  final int id;
  final String name;
  final String specialization;
  final String description;
  final int experience;  final String imageUrl;
  bool isFavorite;

  Master({
    required this.id,
    required this.name,
    required this.specialization,
    required this.description,
    required this.experience,
    required this.imageUrl,
    // Устанавливаем значение по умолчанию, если оно не предоставлено
    this.isFavorite = false,
  });

  factory Master.fromJson(Map<String, dynamic> json) {
    return Master(
      id: json['id'],
      name: json['name'],
      specialization: json['specialization'],
      description: json['description'],
      experience: json['experience'],
      imageUrl: json['image_url'],
      // Парсим новое поле 'is_favorite' из ответа сервера.
      // Если поле отсутствует, значением будет false.
      isFavorite: json['is_favorite'] ?? false,
    );
  }
}
