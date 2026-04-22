import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/prescription_model.dart';

class PrescriptionService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference get _prescriptionCollection {
    return _db.collection('prescriptions');
  }

  // Record prescription metadata without storage upload
  Future<void> uploadPrescription(File imageFile, {String? note, String doctorId = '', List<String> medicines = const [], required String patientId}) async {
    if (!imageFile.existsSync()) {
      throw Exception('Prescription image is required');
    }

    // Save metadata to Firestore (No Firebase Storage)
    final prescription = Prescription(
      id: '',
      patientId: patientId,
      doctorId: doctorId,
      imageUrl: '', // Zero-cost flow: no cloud storage
      imageCaptured: true,
      uploadedAt: DateTime.now().toIso8601String(),
      note: note,
      medicines: medicines,
    );
    
    await _prescriptionCollection.add(prescription.toMap());
  }

  // Stream of prescriptions for a specific patient
  Stream<List<Prescription>> getPrescriptionsForPatient(String patientId) {
    return _prescriptionCollection
        .where('patientId', isEqualTo: patientId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs.map((doc) {
        return Prescription.fromMap(
            doc.id, doc.data() as Map<String, dynamic>);
      }).toList();
      list.sort((a, b) => b.uploadedAt.compareTo(a.uploadedAt));
      return list;
    });
  }

  // Stream of prescriptions for a specific doctor and patient
  Stream<List<Prescription>> getPrescriptionsForDoctorAndPatient(String doctorId, String patientId) {
    return _prescriptionCollection
        .where('doctorId', isEqualTo: doctorId)
        .where('patientId', isEqualTo: patientId)
        // Removed orderBy to avoid requiring a composite index in Firestore
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs.map((doc) {
        return Prescription.fromMap(
            doc.id, doc.data() as Map<String, dynamic>);
      }).toList();
      // Sort locally
      list.sort((a, b) => b.uploadedAt.compareTo(a.uploadedAt));
      return list;
    });
  }

  // Delete a prescription (from Firestore only; Storage cleanup optional)
  Future<void> deletePrescription(String prescriptionId) async {
    await _prescriptionCollection.doc(prescriptionId).delete();
  }
}