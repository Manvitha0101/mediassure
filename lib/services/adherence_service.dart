import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/adherence_log_model.dart';

class AdherenceService {
  final _db = FirebaseFirestore.instance;

  /// Stream of recent adherence logs for a given patient (last 30 days)
  Stream<List<AdherenceLogModel>> getRecentLogs(String patientId) {
    final cutoff = DateTime.now().subtract(const Duration(days: 30));
    return _db
        .collection('adherence_logs')
        .where('patientId', isEqualTo: patientId)
        .where('timestamp', isGreaterThan: Timestamp.fromDate(cutoff))
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((doc) => AdherenceLogModel.fromMap(doc.data(), doc.id)).toList());
  }

  /// Stream of logs for a specific patient on a specific date
  Stream<List<AdherenceLogModel>> getLogsForDay(String patientId, DateTime date) {
    final start = DateTime(date.year, date.month, date.day);
    final end = DateTime(date.year, date.month, date.day, 23, 59, 59);

    return _db
        .collection('adherence_logs')
        .where('patientId', isEqualTo: patientId)
        .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(end))
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((doc) => AdherenceLogModel.fromMap(doc.data(), doc.id)).toList());
  }

  Future<void> logAdherenceStrict({
    required String patientId,
    required String medicineId,
    required String scheduledTime,
    required File photoFile,
  }) async {
    // 1. Generate unique path: adherence_proofs/PATIENT_ID/TIMESTAMP_MED_ID.jpg
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final path = 'adherence_proofs/$patientId/${timestamp}_$medicineId.jpg';
    final ref = FirebaseStorage.instance.ref().child(path);

    // 2. Upload photo
    final uploadTask = await ref.putFile(photoFile);
    final photoUrl = await uploadTask.ref.getDownloadURL();

    // 3. Save metadata to Firestore
    final log = AdherenceLogModel(
      id: '',
      medicineId: medicineId,
      scheduledTime: scheduledTime,
      timestamp: DateTime.now(),
      taken: true,
      photoUrl: photoUrl,
    );

    await _db.collection('adherence_logs').add(log.toMap());
  }
}
