import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/patient_log_model.dart';

class PatientLogService {
  final _db = FirebaseFirestore.instance;

  Stream<List<PatientLogModel>> getLogsStream(String patientId) {
    return _db
        .collection('patient_logs')
        .where('patientId', isEqualTo: patientId)
        .snapshots()
        .map((snap) {
          final list = snap.docs
              .map((doc) => PatientLogModel.fromMap(doc.data(), doc.id))
              .toList();
          list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
          return list;
        });
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
