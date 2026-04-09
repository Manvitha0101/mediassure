// services/medicine_service.dart
// Handles all Firestore operations for medicines under patients/{patientId}/medicines

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/medicine_model.dart';

class MedicineService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Helper: get patient's medicine collection reference
  CollectionReference _medicineCollection(String patientId) {
    return _db.collection('patients').doc(patientId).collection('medications');
  }

  // Stream of patient's medicines (live updates)
  Stream<List<Medicine>> getMedicinesStream(String patientId) {
    return _medicineCollection(patientId).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return Medicine.fromMap(doc.id, doc.data() as Map<String, dynamic>);
      }).toList();
    });
  }

  // Add a new medicine for a patient
  Future<void> addMedicine(String patientId, Medicine medicine) async {
    await _medicineCollection(patientId).add(medicine.toMap());
  }

  // Update an existing medicine
  Future<void> updateMedicine(String patientId, Medicine medicine) async {
    await _medicineCollection(patientId).doc(medicine.id).update(medicine.toMap());
  }

  // Delete a medicine
  Future<void> deleteMedicine(String patientId, String medicineId) async {
    await _medicineCollection(patientId).doc(medicineId).delete();
  }
}