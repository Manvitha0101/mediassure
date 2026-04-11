// services/medicine_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/medicine_model.dart';

class MedicineService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference get _col => _db.collection('medicines');

  // Live stream of all medicines for a patient
  Stream<List<MedicineModel>> getMedicinesStream(String patientId) {
    return _col
        .where('patientId', isEqualTo: patientId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MedicineModel.fromMap(doc.id, doc.data() as Map<String, dynamic>))
            .toList());
  }

  // Add a new medicine — always uses server timestamp for createdAt
  Future<String> addMedicine(MedicineModel medicine) async {
    try {
      final data = medicine.toMap();
      data['createdAt'] = FieldValue.serverTimestamp();
      final ref = await _col.add(data);
      return ref.id;
    } catch (e) {
      print("Error adding medicine: $e");
      rethrow;
    }
  }

  // Update an existing medicine
  Future<void> updateMedicine(MedicineModel medicine) async {
    try {
      await _col.doc(medicine.id).update(medicine.toMap());
    } catch (e) {
      print("Error updating medicine: $e");
      rethrow;
    }
  }

  // Delete a medicine
  Future<void> deleteMedicine(String medicineId) async {
    await _col.doc(medicineId).delete();
  }

  // One-shot fetch (used by caretaker dashboard)
  Future<List<MedicineModel>> getMedicinesOnce(String patientId) async {
    final snapshot = await _col
        .where('patientId', isEqualTo: patientId)
        .get();
    return snapshot.docs
        .map((doc) => MedicineModel.fromMap(doc.id, doc.data() as Map<String, dynamic>))
        .toList();
  }
}