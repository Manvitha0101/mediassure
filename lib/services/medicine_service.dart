// services/medicine_service.dart
// Handles all Firestore operations for medicines

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/medicine_model.dart';

class MedicineService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Helper: get current user's medicine collection reference
  CollectionReference get _medicineCollection {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return _db.collection('users').doc(uid).collection('medicines');
  }

  // Stream of all medicines (live updates)
  Stream<List<Medicine>> getMedicinesStream() {
    return _medicineCollection.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return Medicine.fromMap(doc.id, doc.data() as Map<String, dynamic>);
      }).toList();
    });
  }

  // Add a new medicine
  Future<void> addMedicine(Medicine medicine) async {
    await _medicineCollection.add(medicine.toMap());
  }

  // Update an existing medicine
  Future<void> updateMedicine(Medicine medicine) async {
    await _medicineCollection.doc(medicine.id).update(medicine.toMap());
  }

  // Delete a medicine
  Future<void> deleteMedicine(String medicineId) async {
    await _medicineCollection.doc(medicineId).delete();
  }
}