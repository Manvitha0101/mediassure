import 'package:cloud_firestore/cloud_firestore.dart';

class MedicineModel {
  final String id;
  final String name;
  final String dosage;
  final int? duration; // In days
  final List<String> timings;
  final DateTime startDate;
  final DateTime endDate;
  final bool isActive;
  final String frequency;
  final String patientId;
  final DateTime createdAt;
  final Map<String, Timestamp>? slotTimes; // Map of {"Morning": Timestamp, ...}

  MedicineModel({
    required this.id,
    required this.name,
    required this.dosage,
    this.duration,
    required this.timings,
    required this.startDate,
    required this.endDate,
    required this.isActive,
    required this.frequency,
    required this.patientId,
    required this.createdAt,
    this.slotTimes,
  });

  Map<String, dynamic> toMap() => {
        'name': name,
        'dosage': dosage,
        'duration': duration,
        'timings': timings,
        'startDate': Timestamp.fromDate(startDate),
        'endDate': Timestamp.fromDate(endDate),
        'isActive': isActive,
        'frequency': frequency,
        'patientId': patientId,
        'createdAt': Timestamp.fromDate(createdAt),
        'slotTimes': slotTimes,
      };

  factory MedicineModel.fromMap(String id, Map<String, dynamic> data) {
    return MedicineModel(
      id: id,
      name: data['name'] ?? '',
      dosage: data['dosage'] ?? '',
      duration: data['duration'],
      timings: List<String>.from(data['timings'] ?? []),
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: (data['endDate'] as Timestamp).toDate(),
      isActive: data['isActive'] ?? true,
      frequency: data['frequency'] ?? '',
      patientId: data['patientId'] ?? '',
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      slotTimes: data['slotTimes'] != null
          ? Map<String, Timestamp>.from(data['slotTimes'])
          : null,
    );
  }
}