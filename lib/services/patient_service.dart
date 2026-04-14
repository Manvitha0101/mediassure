import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/patient_model.dart';

class PatientService {
  final _db = FirebaseFirestore.instance;

  /// Stream of all patients assigned to this caretaker
  Stream<List<PatientModel>> getPatientsByCaretaker(String caretakerId) {
    return _db
        .collection('patients')
        .where('caretakerIds', arrayContains: caretakerId)
        .orderBy('name')
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => PatientModel.fromDoc(doc)).toList());
  }

  /// Add a new patient and link to caretaker
  Future<String> addPatient(PatientModel patient) async {
    final ref = await _db.collection('patients').add(patient.toMap());
    return ref.id;
  }

  /// Delete a patient record
  Future<void> deletePatient(String patientId) async {
    await _db.collection('patients').doc(patientId).delete();
  }

  /// Find a patient user by email. Returns their uid if found as a patient role, null otherwise.
  Future<String?> findPatientByEmail(String email) async {
    final query = await _db
        .collection('users')
        .where('email', isEqualTo: email.trim().toLowerCase())
        .where('role', isEqualTo: 'patient')
        .limit(1)
        .get();
    if (query.docs.isEmpty) return null;
    return query.docs.first.id;
  }

  /// Link an existing patient (by their uid) to a caretaker using arrayUnion.
  Future<void> linkPatientByEmail({
    required String patientUid,
    required String caretakerId,
  }) async {
    // Add caretakerId to the patients/{uid}/caretakerIds array
    await _db.collection('patients').doc(patientUid).set({
      'caretakerIds': FieldValue.arrayUnion([caretakerId]),
    }, SetOptions(merge: true));
  }

  /// Link a patient to a caretaker (legacy method kept for compatibility)
  Future<void> linkPatientToCaretaker({
    required String patientId,
    required String caretakerId,
  }) async {
    await _db.collection('patients').doc(patientId).set({
      'patientId': patientId,
      'caretakerIds': FieldValue.arrayUnion([caretakerId]),
    }, SetOptions(merge: true));
  }
}
