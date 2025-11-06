class Favorite {
  final int id;
  final int userId;
  final int masterId;
  final DateTime createdAt;

  Favorite({
    required this.id,
    required this.userId,
    required this.masterId,
    required this.createdAt,
  });

  factory Favorite.fromJson(Map<String, dynamic> json) {
    return Favorite(
      id: json['id'],
      userId: json['user_id'],
      masterId: json['master_id'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}