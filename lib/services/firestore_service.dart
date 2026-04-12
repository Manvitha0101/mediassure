import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/medicine_model.dart';
import '../models/adherence_log_model.dart';
import '../models/app_notification_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // --- MEDICINES ---
  
  // Fetch medicines for a specific patient
  Stream<List<MedicineModel>> getMedications(String patientId) {
    return _db
        .collection('medicines')
        .where('patientId', isEqualTo: patientId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MedicineModel.fromMap(doc.id, doc.data()))
            .toList());
  }

  // --- ADHERENCE LOGS ---

  // Fetch adherence logs for a specific patient
  Stream<List<AdherenceLogModel>> getLogs(String patientId) {
    return _db
        .collection('adherence_logs')
        .where('patientId', isEqualTo: patientId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AdherenceLogModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Add an adherence log
  Future<void> addLog({
    required String patientId,
    required String medicineId,
    required String scheduledTime,
    required bool taken,
    Map<String, double>? location,
    String? proofImageUrl,
  }) async {
    await _db.collection('adherence_logs').add({
      'patientId': patientId,
      'medicineId': medicineId,
      'scheduledTime': scheduledTime,
      'taken': taken,
      'timestamp': FieldValue.serverTimestamp(),
      if (location != null) 'location': location,
      if (proofImageUrl != null) 'proofImageUrl': proofImageUrl,
    });
  }

  // --- NOTIFICATIONS ---

  // Fetch notifications for a specific user (can be patient, doctor, or caretaker)
  Stream<List<AppNotificationModel>> getNotifications(String userId) {
    return _db
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AppNotificationModel.fromMap(doc.data(), doc.id))
            .toList());
  }
}
