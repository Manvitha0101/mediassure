// models/adherence_log_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

DateTime _parseTimestamp(dynamic value) {
  if (value == null) return DateTime.now();
  if (value is Timestamp) return value.toDate();
  if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
  return DateTime.now();
}

class AdherenceLogModel {
  final String id;
  final String patientId;
  final String medicineId;
  final bool taken;
  final String scheduledTime;
  final DateTime timestamp;
  final String proofImageUrl; // ALWAYS required
  final Map<String, double> location; // lat, long

  AdherenceLogModel({
    required this.id,
    required this.patientId,
    required this.medicineId,
    required this.taken,
    required this.scheduledTime,
    required this.timestamp,
    required this.proofImageUrl,
    required this.location,
  });

  Map<String, dynamic> toMap() {
    return {
      'patientId': patientId,
      'medicineId': medicineId,
      'taken': taken,
      'scheduledTime': scheduledTime,
      'timestamp': timestamp, 
      'proofImageUrl': proofImageUrl,
      'location': location,
    };
  }

  factory AdherenceLogModel.fromMap(Map<String, dynamic> map, String id) {
    return AdherenceLogModel(
      id: id,
      patientId: map['patientId'] ?? '',
      medicineId: map['medicineId'] ?? '',
      taken: map['taken'] ?? false,
      scheduledTime: map['scheduledTime'] ?? '',
      timestamp: _parseTimestamp(map['timestamp']),
      proofImageUrl: map['proofImageUrl'] ?? '',
      location: map['location'] != null 
          ? Map<String, double>.from(
              (map['location'] as Map).map(
                (k, v) => MapEntry(k.toString(), (v as num).toDouble()),
              ),
            ) 
          : {'latitude': 0.0, 'longitude': 0.0},
    );
  }
}
