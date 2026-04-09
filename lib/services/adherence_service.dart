// services/adherence_service.dart
// Dedicated service for logging adherence (taken/missed) under patients/{patientId}/adherenceLogs

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/adherence_log_model.dart';

class AdherenceService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  CollectionReference _adherenceCollection(String patientId) {
    return _db.collection('patients').doc(patientId).collection('adherenceLogs');
  }

  // Log a taken or missed dose
  Future<void> logAdherence(String patientId, String medicineId, AdherenceStatus status, {File? photoFile}) async {
    String? imageUrl;

    if (photoFile != null) {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = _storage.ref().child('adherenceProofs/$patientId/$fileName');
      await ref.putFile(photoFile);
      imageUrl = await ref.getDownloadURL();
    }

    final log = AdherenceLogModel(
      logId: '',
      medicineId: medicineId,
      status: status,
      timestamp: DateTime.now(),
      imageUrl: imageUrl,
    );
    await _adherenceCollection(patientId).add(log.toMap());
  }

  // Get recent logs
  Stream<List<AdherenceLogModel>> getRecentLogs(String patientId) {
    return _adherenceCollection(patientId)
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return AdherenceLogModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }
}
