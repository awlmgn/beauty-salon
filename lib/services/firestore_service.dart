import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/review.dart';
import '../models/appointment.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Reviews
  Future<void> addReview(Review review) async {
    await _firestore.collection('reviews').doc(review.id).set(review.toMap());
  }

  Stream<List<Review>> getReviews() {
    return _firestore
        .collection('reviews')
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => Review.fromMap(doc.data()))
        .toList());
  }

  // Appointments
  Future<void> addAppointment(Appointment appointment) async {
    await _firestore.collection('appointments').doc(appointment.id).set(appointment.toMap());
  }

  Stream<List<Appointment>> getAppointments() {
    return _firestore
        .collection('appointments')
        .orderBy('dateTime')
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => Appointment.fromMap(doc.data()))
        .toList());
  }

  // Проверка доступности времени
  Future<bool> isTimeSlotAvailable(DateTime dateTime, String masterName) async {
    final query = await _firestore
        .collection('appointments')
        .where('masterName', isEqualTo: masterName)
        .where('dateTime', isEqualTo: dateTime.millisecondsSinceEpoch)
        .get();

    return query.docs.isEmpty;
  }
}