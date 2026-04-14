import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
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

  /// Log adherence with image (strict mode)
  Future<void> logAdherenceStrict({
    required String patientId,
    required String medicineId,
    required String scheduledTime,
    required File photoFile,
  }) async {
    // Note: In this version, we are not uploading to Firebase Storage (as per previous requirements)
    // We just save the metadata and the local path (or a placeholder).
    final log = AdherenceLogModel(
      id: '',
      medicineId: medicineId,
      scheduledTime: scheduledTime,
      timestamp: DateTime.now(),
      taken: true,
    );

    await _db.collection('adherence_logs').add(log.toMap());
  }
}
