// models/patient_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

DateTime? _parsePatientDate(dynamic value) {
  if (value == null) return null;
  if (value is Timestamp) return value.toDate();
  if (value is String) return DateTime.tryParse(value);
  return null;
}

class PatientModel {
  final String patientId;
  final String name;
  final int age;
  final String? gender;
  final String? bloodGroup;
  final List<String> medicalConditions;
  final List<String> caretakerIds;
  final List<String> doctorIds;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  PatientModel({
    required this.patientId,
    required this.name,
    required this.age,
    this.gender,
    this.bloodGroup,
    this.medicalConditions = const [],
    this.caretakerIds = const [],
    this.doctorIds = const [],
    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'age': age,
      'gender': gender,
      'bloodGroup': bloodGroup,
      'medicalConditions': medicalConditions,
      'caretakerIds': caretakerIds,
      'doctorIds': doctorIds,
      // createdAt/updatedAt are injected as FieldValue.serverTimestamp() by PatientService
    };
  }

  factory PatientModel.fromMap(Map<String, dynamic> map, String id) {
    return PatientModel(
      patientId:         id,
      name:              map['name'] ?? '',
      age:               map['age'] ?? 0,
      gender:            map['gender'],
      bloodGroup:        map['bloodGroup'],
      medicalConditions: List<String>.from(map['medicalConditions'] ?? []),
      caretakerIds:      List<String>.from(map['caretakerIds'] ?? []),
      doctorIds:         List<String>.from(map['doctorIds'] ?? []),
      createdAt:         _parsePatientDate(map['createdAt']),
      updatedAt:         _parsePatientDate(map['updatedAt']),
    );
  }
}
