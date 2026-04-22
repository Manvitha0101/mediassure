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
  final String? imageUrl;
  
  AdherenceLogModel({
    required this.id,
    required this.patientId,
    required this.medicineId,
    required this.caretakerId,
    required this.caretakerName,
    required this.scheduledTime,
    required this.timestamp,
    required this.taken,
    this.imageUrl,
  });

  factory AdherenceLogModel.fromMap(Map<String, dynamic> data, String id, {bool includeImage = false}) {
    return AdherenceLogModel(
      id: id,
      patientId: data['patientId'] ?? '',
      medicineId: data['medicineId'] ?? '',
      caretakerId: data['caretakerId'] ?? '',
      caretakerName: data['caretakerName'] ?? '',
      scheduledTime: data['scheduledTime'] ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      taken: data['taken'] ?? false,
      imageUrl: data['imageUrl'],
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
        if (imageUrl != null) 'imageUrl': imageUrl,
      };
}
