import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/medicine_model.dart';

class MedicineService {
  final _db = FirebaseFirestore.instance;

  /// Stream of medicines for a given patient
  Stream<List<MedicineModel>> getMedicinesStream(String patientId) {
    return _db
        .collection('medicines')
        .where('patientId', isEqualTo: patientId)
        .snapshots()
        .map((snap) =>
            snap.docs.map((doc) => MedicineModel.fromMap(doc.id, doc.data())).toList());
  }

  /// Add a new medicine
  Future<String> addMedicine(MedicineModel medicine) async {
    final ref = await _db.collection('medicines').add(medicine.toMap());
    return ref.id;
  }

  /// Update an existing medicine
  Future<void> updateMedicine(MedicineModel medicine) async {
    await _db.collection('medicines').doc(medicine.id).update(medicine.toMap());
  }

  /// Delete a medicine
  Future<void> deleteMedicine(String id) async {
    await _db.collection('medicines').doc(id).delete();
  }
}