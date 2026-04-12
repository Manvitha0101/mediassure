import 'package:cloud_firestore/cloud_firestore.dart';

class PatientModel {
  final String patientId;
  final String name;
  final String email;
  final String caretakerId;
  final String? gender;
  final int? age;

  PatientModel({
    required this.patientId,
    required this.name,
    required this.email,
    required this.caretakerId,
    this.gender,
    this.age,
  });

  Map<String, dynamic> toMap() => {
        'name': name,
        'email': email,
        'caretakerId': caretakerId,
        'gender': gender,
        'age': age,
        'createdAt': FieldValue.serverTimestamp(),
      };

  factory PatientModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PatientModel(
      patientId: doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      caretakerId: data['caretakerId'] ?? '',
      gender: data['gender'],
      age: data['age'],
    );
  }
}
