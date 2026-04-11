import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/prescription_model.dart';

class PrescriptionService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference get _prescriptionCollection {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return _db.collection('users').doc(uid).collection('prescriptions');
  }

  // Record prescription metadata without storage upload
  Future<void> uploadPrescription(File imageFile, {String? note}) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    if (!imageFile.existsSync()) {
      throw Exception('Prescription image is required');
    }

    // Save metadata to Firestore (No Firebase Storage)
    final prescription = Prescription(
      id: '',
      patientId: uid,
      imageUrl: '', // Zero-cost flow: no cloud storage
      imageCaptured: true,
      uploadedAt: DateTime.now().toIso8601String(),
      note: note,
    );
    
    await _prescriptionCollection.add(prescription.toMap());
  }

  // Stream of all prescriptions (newest first)
  Stream<List<Prescription>> getPrescriptionsStream() {
    return _prescriptionCollection
        .orderBy('uploadedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Prescription.fromMap(
            doc.id, doc.data() as Map<String, dynamic>);
      }).toList();
    });
  }

  // Delete a prescription (from Firestore only; Storage cleanup optional)
  Future<void> deletePrescription(String prescriptionId) async {
    await _prescriptionCollection.doc(prescriptionId).delete();
  }
}