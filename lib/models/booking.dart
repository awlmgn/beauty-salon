// models/booking.dart
class Booking {
  final int id;
  final int userId;
  final int masterId;
  final DateTime dateTime;
  final String service;
  final String status; // 'pending', 'confirmed', 'completed', 'cancelled'

  Booking({required this.id, required this.userId, required this.masterId,
    required this.dateTime, required this.service, required this.status});
}