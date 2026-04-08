// services/prescription_service.dart
// Handles prescription image upload to Firebase Storage and metadata to Firestore

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/prescription_model.dart';

class PrescriptionService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  CollectionReference get _prescriptionCollection {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return _db.collection('users').doc(uid).collection('prescriptions');
  }

  // Upload image file and save URL to Firestore
  Future<void> uploadPrescription(File imageFile, {String? note}) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';

    // Upload to Firebase Storage
    final ref = _storage.ref().child('prescriptions/$uid/$fileName');
    await ref.putFile(imageFile);
    final downloadUrl = await ref.getDownloadURL();

    // Save metadata to Firestore
    final prescription = Prescription(
      id: '',
      imageUrl: downloadUrl,
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