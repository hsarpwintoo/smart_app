import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/checkin_model.dart';

/// Handles all read/write operations against the Firestore `checkins`
/// collection.
///
/// Usage:
///   FirestoreService.instance.saveCheckIn(model)
///   FirestoreService.instance.getCheckInsStream()
class FirestoreService {
  FirestoreService._();
  static final FirestoreService instance = FirestoreService._();

  final CollectionReference<Map<String, dynamic>> _checkinsRef =
      FirebaseFirestore.instance.collection('checkins');

  // ── Write ──────────────────────────────────────────────────────────────

  /// Saves [checkIn] to the `checkins` collection.
  /// Returns the auto-generated Firestore document ID.
  Future<String> saveCheckIn(CheckInModel checkIn) async {
    final docRef = await _checkinsRef.add(checkIn.toFirestore());
    return docRef.id;
  }

  // ── Read ───────────────────────────────────────────────────────────────

  /// Real-time stream of all check-in records, newest first.
  Stream<List<CheckInModel>> getCheckInsStream() {
    return _checkinsRef
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map(CheckInModel.fromFirestore).toList(),
        );
  }
}
