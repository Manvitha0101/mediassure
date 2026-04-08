// services/caretaker_service.dart
// Handles Firestore CRUD for caretaker info

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/caretaker_model.dart';

class CaretakerService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference get _caretakerCollection {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return _db.collection('users').doc(uid).collection('caretakers');
  }

  Stream<List<Caretaker>> getCaretakersStream() {
    return _caretakerCollection.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return Caretaker.fromMap(doc.id, doc.data() as Map<String, dynamic>);
      }).toList();
    });
  }

  Future<void> addCaretaker(Caretaker caretaker) async {
    await _caretakerCollection.add(caretaker.toMap());
  }

  Future<void> updateCaretaker(Caretaker caretaker) async {
    await _caretakerCollection.doc(caretaker.id).update(caretaker.toMap());
  }

  Future<void> deleteCaretaker(String id) async {
    await _caretakerCollection.doc(id).delete();
  }
}