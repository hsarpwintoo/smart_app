import 'package:cloud_firestore/cloud_firestore.dart';

/// Data model for a single check-in record stored in Firestore.
class CheckInModel {
  final String? id; // Firestore document ID (null before first save)
  final String studentId;
  final DateTime timestamp;
  final double latitude;
  final double longitude;
  final String qrCode;
  final String previousTopic;
  final String expectedTopic;
  final int moodScore; // 1 = Low … 5 = Great

  const CheckInModel({
    this.id,
    required this.studentId,
    required this.timestamp,
    required this.latitude,
    required this.longitude,
    required this.qrCode,
    required this.previousTopic,
    required this.expectedTopic,
    required this.moodScore,
  });

  // ── Serialisation ──────────────────────────────────────────────────────

  /// Converts the model to a Map suitable for writing to Firestore.
  Map<String, dynamic> toFirestore() {
    return {
      'studentId': studentId,
      'timestamp': Timestamp.fromDate(timestamp),
      'latitude': latitude,
      'longitude': longitude,
      'qrCode': qrCode,
      'previousTopic': previousTopic,
      'expectedTopic': expectedTopic,
      'moodScore': moodScore,
    };
  }

  /// Creates a [CheckInModel] from a Firestore [DocumentSnapshot].
  factory CheckInModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CheckInModel(
      id: doc.id,
      studentId: data['studentId'] as String? ?? '',
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      latitude: (data['latitude'] as num).toDouble(),
      longitude: (data['longitude'] as num).toDouble(),
      qrCode: data['qrCode'] as String? ?? '',
      previousTopic: data['previousTopic'] as String? ?? '',
      expectedTopic: data['expectedTopic'] as String? ?? '',
      moodScore: (data['moodScore'] as num).toInt(),
    );
  }
}
