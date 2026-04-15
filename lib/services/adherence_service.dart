import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../models/adherence_log_model.dart';
import 'image_picker_service.dart';
import 'patient_service.dart';

class AdherenceService {
  final _db = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;
  final _imagePicker = ImagePickerService();
  final _patientService = PatientService();
  static const String _colAdherenceLogs = 'adherenceLogs';
  static const String _colPatientLogs = 'patient_logs';

  /// Stream of recent adherence logs for a given patient (last 30 days)
  Stream<List<AdherenceLogModel>> getRecentLogs(String patientId) {
    return _db
        .collection(_colAdherenceLogs)
        .where('patientId', isEqualTo: patientId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snap) {
          // Avoid composite-index requirement by filtering client-side.
          final cutoff = DateTime.now().subtract(const Duration(days: 30));
          final all = snap.docs
              .map((doc) => AdherenceLogModel.fromMap(doc.data(), doc.id))
              .toList();
          return all.where((l) => l.timestamp.isAfter(cutoff)).toList();
        });
  }

  /// Logs for a specific day (00:00..23:59) for adherence calendar views.
  Stream<List<AdherenceLogModel>> getLogsForDay(String patientId, DateTime day) {
    final start = DateTime(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));
    return _db
        .collection(_colAdherenceLogs)
        .where('patientId', isEqualTo: patientId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snap) {
          // Avoid composite-index requirement by filtering client-side.
          final all = snap.docs
              .map((doc) => AdherenceLogModel.fromMap(doc.data(), doc.id))
              .toList();
          return all
              .where((l) => !l.timestamp.isBefore(start) && l.timestamp.isBefore(end))
              .toList();
        });
  }

  Future<void> logAdherenceStrict({
    required String patientId,
    required String medicineId,
    required String scheduledTime,
    required bool taken,
    String? medicineName,
    String? caretakerId,
    String? caretakerName,
    String? imageUrl,
  }) async {
    final log = AdherenceLogModel(
      id: '',
      patientId: patientId,
      medicineId: medicineId,
      caretakerId: caretakerId ?? '',
      caretakerName: caretakerName ?? '',
      scheduledTime: scheduledTime,
      timestamp: DateTime.now(),
      taken: taken,
      imageUrl: imageUrl,
    );

    await _db.collection(_colAdherenceLogs).add(log.toMap());

    // Also create a patient log entry automatically
    if (medicineName != null &&
        caretakerId != null &&
        caretakerName != null &&
        taken == true) {
      final now = DateTime.now();
      final String amPm = now.hour >= 12 ? 'PM' : 'AM';
      final int hour12 =
          now.hour > 12 ? now.hour - 12 : (now.hour == 0 ? 12 : now.hour);
      final String timeStr =
          '$hour12:${now.minute.toString().padLeft(2, '0')} $amPm';

      final logMessage = "$medicineName given at $timeStr";

      final patientLogRef = _db.collection(_colPatientLogs).doc();
      await patientLogRef.set({
        'patientId': patientId,
        'message': logMessage,
        'caretakerId': caretakerId,
        'caretakerName': caretakerName,
        'timestamp': FieldValue.serverTimestamp(),
      });
    }
  }

  /// Caretaker-only: capture a proof photo, upload to Storage, then write `adherenceLogs`.
  ///
  /// Storage path: `adherence_proofs/{patientId}/{medicineId_timestamp}.jpg`
  Future<void> markTakenWithCamera({
    required String patientId,
    required String medicineId,
    required String medicineName,
    required String caretakerId,
    required String caretakerName,
    required String scheduledTime,
  }) async {
    final linked = await _patientService.isCaretakerLinked(
      patientId: patientId,
      caretakerId: caretakerId,
    );
    if (!linked) {
      throw Exception('Not linked to this patient.');
    }

    final file = await _imagePicker.pickFromCamera();
    if (file == null) {
      throw Exception('Image is required to mark as taken.');
    }

    final ts = DateTime.now().millisecondsSinceEpoch;
    final objectPath = 'adherence_proofs/$patientId/${medicineId}_$ts.jpg';
    final ref = _storage.ref().child(objectPath);

    await ref.putFile(
      file,
      SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {
          'patientId': patientId,
          'medicineId': medicineId,
          'caretakerId': caretakerId,
          'scheduledTime': scheduledTime,
        },
      ),
    );

    final downloadUrl = await ref.getDownloadURL();

    await logAdherenceStrict(
      patientId: patientId,
      medicineId: medicineId,
      medicineName: medicineName,
      caretakerId: caretakerId,
      caretakerName: caretakerName,
      scheduledTime: scheduledTime,
      taken: true,
      imageUrl: downloadUrl,
    );
  }
}
