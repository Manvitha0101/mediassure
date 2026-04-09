// services/patient_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/patient_model.dart';
import '../models/user_role_model.dart';

class PatientService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Get a single patient
  Future<PatientModel?> getPatient(String patientId) async {
    DocumentSnapshot doc = await _db.collection('patients').doc(patientId).get();
    if (doc.exists && doc.data() != null) {
      return PatientModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    }
    return null;
  }

  // For caretakers/doctors: get list of assigned patients
  Stream<List<PatientModel>> getAssignedPatients(String userId, UserRole role) {
    String arrayField = role == UserRole.doctor 
        ? 'assignedDoctorIds' 
        : 'assignedCaretakerIds';
        
    return _db
        .collection('patients')
        .where(arrayField, arrayContains: userId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => PatientModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  // Invite/Link (Add caregiver/doctor id to patient's list)
  // Usually this is done via an invite code where the professional inputs a code 
  // and the patient's record is updated.
  Future<void> linkProfessionalToPatient(String patientId, String professionalId, UserRole role) async {
    String arrayField = role == UserRole.doctor 
        ? 'assignedDoctorIds' 
        : 'assignedCaretakerIds';
        
    await _db.collection('patients').doc(patientId).update({
      arrayField: FieldValue.arrayUnion([professionalId])
    });
  }
}
