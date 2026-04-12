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
}
