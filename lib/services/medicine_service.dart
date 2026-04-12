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
}