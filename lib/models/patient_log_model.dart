import 'package:cloud_firestore/cloud_firestore.dart';

class PatientLogModel {
  final String id;
  final String patientId;
  final String message;
  final String caretakerId;
  final String caretakerName;
  final DateTime timestamp;

  PatientLogModel({
    required this.id,
    required this.patientId,
    required this.message,
    required this.caretakerId,
    required this.caretakerName,
    required this.timestamp,
  });

  factory PatientLogModel.fromMap(Map<String, dynamic> data, String id) {
    return PatientLogModel(
      id: id,
      patientId: data['patientId'] ?? '',
      message: data['message'] ?? '',
      caretakerId: data['caretakerId'] ?? '',
      caretakerName: data['caretakerName'] ?? '',
      timestamp: (data['timestamp'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
        'patientId': patientId,
        'message': message,
        'caretakerId': caretakerId,
        'caretakerName': caretakerName,
        'timestamp': Timestamp.fromDate(timestamp),
      };
}
