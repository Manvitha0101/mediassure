import 'package:cloud_firestore/cloud_firestore.dart';

class MedicineModel {
  final String id;
  final String name;
  final String dosage;
  final List<String> timings;
  final DateTime startDate;
  final DateTime endDate;
  final bool isActive;
  final String frequency;

  MedicineModel({
    required this.id,
    required this.name,
    required this.dosage,
    required this.timings,
    required this.startDate,
    required this.endDate,
    required this.isActive,
    required this.frequency,
  });

  factory MedicineModel.fromMap(String id, Map<String, dynamic> data) {
    return MedicineModel(
      id: id,
      name: data['name'] ?? '',
      dosage: data['dosage'] ?? '',
      timings: List<String>.from(data['timings'] ?? []),
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: (data['endDate'] as Timestamp).toDate(),
      isActive: data['isActive'] ?? true,
      frequency: data['frequency'] ?? '',
    );
  }
}