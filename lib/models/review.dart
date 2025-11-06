class Review {
  final int id;
  final String userName;
  final String text;
  final int rating;
  final DateTime date;
  final int? masterId;

  Review({
    required this.id,
    required this.userName,
    required this.text,
    required this.rating,
    required this.date,
    this.masterId,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id'],
      userName: json['user_name'] ?? json['userName'] ?? 'Аноним',
      text: json['text'],
      rating: json['rating'],
      date: DateTime.parse(json['date'] ?? json['created_at']),
      masterId: json['master_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'rating': rating,
      if (masterId != null) 'master_id': masterId,
    };
  }
}