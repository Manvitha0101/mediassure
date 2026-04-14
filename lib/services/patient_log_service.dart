import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/patient_log_model.dart';

class PatientLogService {
  final _db = FirebaseFirestore.instance;

  /// Stream of patient logs ordered by timestamp
  Stream<List<PatientLogModel>> getLogsStream(String patientId) {
    return _db
        .collection('patient_logs')
        .where('patientId', isEqualTo: patientId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => PatientLogModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  /// Add a new patient log
  Future<void> addLog({
    required String patientId,
    required String message,
    required String caretakerId,
    required String caretakerName,
  }) async {
    final log = PatientLogModel(
      id: '',
      patientId: patientId,
      message: message,
      caretakerId: caretakerId,
      caretakerName: caretakerName,
      timestamp: DateTime.now(),
    );
    await _db.collection('patient_logs').add(log.toMap());
  }
}
