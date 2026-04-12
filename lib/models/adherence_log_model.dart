import 'package:cloud_firestore/cloud_firestore.dart';

class AdherenceLogModel {
  final String id;
  final String medicineId;
  final String scheduledTime;
  final DateTime timestamp;
  final bool taken;

  AdherenceLogModel({
    required this.id,
    required this.medicineId,
    required this.scheduledTime,
    required this.timestamp,
    required this.taken,
  });

  factory AdherenceLogModel.fromMap(Map<String, dynamic> data, String id) {
    return AdherenceLogModel(
      id: id,
      medicineId: data['medicineId'] ?? '',
      scheduledTime: data['scheduledTime'] ?? '',
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      taken: data['taken'] ?? false,
    );
  }
}
