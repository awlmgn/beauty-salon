class Master {
  final int id;
  final String name;
  final String specialization;
  final String description;
  final int experience;  final String imageUrl;
  final double rating;
  bool isFavorite;

  Master({
    required this.id,
    required this.name,
    required this.specialization,
    required this.description,
    required this.experience,
    required this.imageUrl,
    this.rating = 0.0,
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
      rating: json['rating'] != null ? double.parse(json['rating'].toString()) : 0.0,
      isFavorite: json['is_favorite'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'specialization': specialization,
      'description': description,
      'experience': experience,
      'rating': rating,
      'image_url': imageUrl,
    };
  }
}
