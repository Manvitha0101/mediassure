// services/patient_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/patient_model.dart';

class PatientService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference get _col => _db.collection('patients');

  // Get a single patient by doc ID
  Future<PatientModel?> getPatient(String patientId) async {
    final doc = await _col.doc(patientId).get();
    if (doc.exists && doc.data() != null) {
      return PatientModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    }
    return null;
  }

  // Stream of patients assigned to a caretaker/doctor
  Stream<List<PatientModel>> getAssignedPatients(String userId, String role) {
    final field = role == 'doctor' ? 'doctorIds' : 'caretakerIds';
    return _col
        .where(field, arrayContains: userId)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => PatientModel.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList());
  }

  // Create a new patient document and return its generated doc ID
  Future<String> createPatient(PatientModel patient) async {
    final data = patient.toMap();
    data['createdAt'] = FieldValue.serverTimestamp();
    data['updatedAt'] = FieldValue.serverTimestamp();
    final ref = await _col.add(data);
    return ref.id;
  }

  // Add a caretaker/doctor reference to a patient
  Future<void> linkProfessionalToPatient(
      String patientId, String professionalId, String role) async {
    final field = role == 'doctor' ? 'doctorIds' : 'caretakerIds';
    await _col.doc(patientId).update({
      field: FieldValue.arrayUnion([professionalId]),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Add this patient's ID to the caretaker's users document patientIds array
  Future<void> linkPatientToUser(String userId, String patientId) async {
    await _db.collection('users').doc(userId).update({
      'patientIds': FieldValue.arrayUnion([patientId]),
    });
  }
}
