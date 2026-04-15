import 'package:cloud_firestore/cloud_firestore.dart';

class AdherenceLogModel {
  final String id;
  final String patientId;
  final String medicineId;
  final String caretakerId;
  final String caretakerName;
  final String scheduledTime;
  final DateTime timestamp;
  final bool taken;
  /// Base64-encoded proof image (optional).
  ///
  /// Canonical field name in Firestore: `imageBase64`
  final String? imageBase64;

  AdherenceLogModel({
    required this.id,
    required this.patientId,
    required this.medicineId,
    required this.caretakerId,
    required this.caretakerName,
    required this.scheduledTime,
    required this.timestamp,
    required this.taken,
    this.imageBase64,
  });

  factory AdherenceLogModel.fromMap(Map<String, dynamic> data, String id) {
    return AdherenceLogModel(
      id: id,
      patientId: data['patientId'] ?? '',
      medicineId: data['medicineId'] ?? '',
      caretakerId: data['caretakerId'] ?? '',
      caretakerName: data['caretakerName'] ?? '',
      scheduledTime: data['scheduledTime'] ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      taken: data['taken'] ?? false,
      imageBase64: data['imageBase64'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
        'patientId': patientId,
        'medicineId': medicineId,
        'caretakerId': caretakerId,
        'caretakerName': caretakerName,
        'scheduledTime': scheduledTime,
        'timestamp': Timestamp.fromDate(timestamp),
        'taken': taken,
        if (imageBase64 != null) 'imageBase64': imageBase64,
      };
}
