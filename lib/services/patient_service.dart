import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/patient_model.dart';

class PatientService {
  final _db = FirebaseFirestore.instance;

  /// Stream of all patients assigned to this caretaker
  Stream<List<PatientModel>> getPatientsByCaretaker(String caretakerId) {
    return _db
        .collection('patients')
        .where('caretakerId', isEqualTo: caretakerId)
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
}
