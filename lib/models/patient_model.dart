import 'package:cloud_firestore/cloud_firestore.dart';

class PatientModel {
  final String patientId;
  final String name;
  final String email;
  final List<String> caretakerIds;
  final List<String> doctorIds;
  final String gender;
  final int age;
  final String? bloodGroup;
  final List<String> medicalConditions;

  PatientModel({
    required this.patientId,
    required this.name,
    required this.email,
    required this.caretakerIds,
    this.doctorIds = const [],
    required this.gender,
    required this.age,
    this.bloodGroup,
    this.medicalConditions = const [],
  });

  Map<String, dynamic> toMap() => {
        'name': name,
        'email': email,
        'caretakerIds': caretakerIds,
        'doctorIds': doctorIds,
        'gender': gender,
        'age': age,
        'bloodGroup': bloodGroup,
        'medicalConditions': medicalConditions,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

  factory PatientModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PatientModel(
      patientId: doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      caretakerIds: List<String>.from(data['caretakerIds'] ?? []),
      doctorIds: List<String>.from(data['doctorIds'] ?? []),
      gender: data['gender'] ?? 'Unknown',
      age: data['age'] ?? 0,
      bloodGroup: data['bloodGroup'],
      medicalConditions: List<String>.from(data['medicalConditions'] ?? []),
    );
  }
}

/// Lightweight caretaker-side patient reference used by some screens.
class LinkedPatient {
  final String uid;
  final String name;

  const LinkedPatient({
    required this.uid,
    required this.name,
  });
}
