// models/medicine_model.dart
// Represents a single medicine entry stored in Firestore under medicines collection

import 'package:cloud_firestore/cloud_firestore.dart';

DateTime _parseDate(dynamic value, DateTime fallback) {
  if (value == null) return fallback;
  if (value is Timestamp) return value.toDate();
  if (value is String) return DateTime.tryParse(value) ?? fallback;
  return fallback;
}

class MedicineModel {
  final String id;
  final String name;
  final String dosage;
  final String frequency;
  final List<String> timings; // e.g., ["Morning", "Night"]
  final DateTime startDate;
  final DateTime endDate;
  final String patientId;
  final bool isActive;
  final DateTime createdAt;

  MedicineModel({
    required this.id,
    required this.name,
    required this.dosage,
    required this.frequency,
    required this.timings,
    required this.startDate,
    required this.endDate,
    required this.patientId,
    this.isActive = true,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'dosage': dosage,
      'frequency': frequency,
      'timings': timings,
      'startDate': startDate,
      'endDate': endDate,
      'patientId': patientId,
      'isActive': isActive,
      // createdAt is set to serverTimestamp by MedicineService.addMedicine
    };
  }

  factory MedicineModel.fromMap(String id, Map<String, dynamic> map) {
    final now = DateTime.now();
    return MedicineModel(
      id: id,
      name: map['name'] ?? '',
      dosage: map['dosage'] ?? '',
      frequency: map['frequency'] ?? '',
      timings: List<String>.from(map['timings'] ?? []),
      startDate: _parseDate(map['startDate'], now),
      endDate: _parseDate(map['endDate'], now.add(const Duration(days: 30))),
      patientId: map['patientId'] ?? '',
      isActive: map['isActive'] ?? true,
      createdAt: _parseDate(map['createdAt'], now),
    );
  }
}