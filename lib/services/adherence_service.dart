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

  Future<void> logAdherenceStrict({
    required String patientId,
    required String medicineId,
    required String medicineName,
    required String caretakerId,
    required String caretakerName,
    required String scheduledTime,
    File? photoFile, // optional for caretakers marking manually
  }) async {
    // Note: In this version, we are not uploading to Firebase Storage.
    // We just save the metadata mapping the caretaker.
    final log = AdherenceLogModel(
      id: '',
      patientId: patientId,
      medicineId: medicineId,
      caretakerId: caretakerId,
      caretakerName: caretakerName,
      scheduledTime: scheduledTime,
      timestamp: DateTime.now(),
      taken: true,
    );

    await _db.collection('adherence_logs').add(log.toMap());

    // Also create a patient log entry automatically
    final String amPm = DateTime.now().hour >= 12 ? 'PM' : 'AM';
    final int hour12 = DateTime.now().hour > 12 ? DateTime.now().hour - 12 : (DateTime.now().hour == 0 ? 12 : DateTime.now().hour);
    final String timeStr = '$hour12:${DateTime.now().minute.toString().padLeft(2, '0')} $amPm';
    
    final logMessage = "$medicineName given at $timeStr";
    
    final patientLogRef = _db.collection('patient_logs').doc();
    await patientLogRef.set({
      'patientId': patientId,
      'message': logMessage,
      'caretakerId': caretakerId,
      'caretakerName': caretakerName,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }
}
