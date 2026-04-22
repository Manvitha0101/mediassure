import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/medicine_model.dart';
import '../models/adherence_log_model.dart';
import '../models/app_notification_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  static const String _colMedicines = 'medicines';
  static const String _colAdherenceLogs = 'adherenceLogs';

  // --- MEDICINES ---
  
  // Fetch medicines for a specific patient
  Stream<List<MedicineModel>> getMedications(String patientId) {
    return _db
        .collection(_colMedicines)
        .where('patientId', isEqualTo: patientId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MedicineModel.fromMap(doc.id, doc.data()))
            .toList());
  }

  // --- ADHERENCE LOGS ---

  // Fetch adherence logs for a specific patient
  Stream<List<AdherenceLogModel>> getLogs(String patientId) {
    // Canonical collection name: `adherenceLogs`
    return _db
        .collection(_colAdherenceLogs)
        .where('patientId', isEqualTo: patientId)
        .snapshots()
        .map((snapshot) {
          final list = snapshot.docs
              .map((doc) => AdherenceLogModel.fromMap(doc.data(), doc.id, includeImage: false))
              .toList();
          list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
          return list;
        });
  }

  // Add an adherence log
  Future<void> addLog({
    required String patientId,
    required String medicineId,
    required String scheduledTime,
    required bool taken,
    Map<String, double>? location,
    String? caretakerId,
    String? caretakerName,
  }) async {
    await _db.collection(_colAdherenceLogs).add({
      'patientId': patientId,
      'medicineId': medicineId,
      if (caretakerId != null) 'caretakerId': caretakerId,
      if (caretakerName != null) 'caretakerName': caretakerName,
      'scheduledTime': scheduledTime,
      'taken': taken,
      'timestamp': FieldValue.serverTimestamp(),
      if (location != null) 'location': location,
    });
  }

  // --- NOTIFICATIONS ---

  // Fetch notifications for a specific user (can be patient, doctor, or caretaker)
  Stream<List<AppNotificationModel>> getNotifications(String userId) {
    return _db
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          final list = snapshot.docs
              .map((doc) => AppNotificationModel.fromMap(doc.data(), doc.id))
              .toList();
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list;
        });
  }
}
