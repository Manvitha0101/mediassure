import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import '../models/patient_model.dart';

class PatientService {
  final _db = FirebaseFirestore.instance;
  static const String _colUsers = 'users';
  static const String _colPatients = 'patients';

  /// Backward-compatible alias (older UI calls).
  Stream<List<PatientModel>> getPatientsByCaretaker(String caretakerId) {
    return getLinkedPatientsStream(caretakerId);
  }

  /// Stream of linked patients for caretaker.
  ///
  /// CRITICAL: does NOT query the full `/patients` collection.
  /// Reads `/users/{caretakerUid}.patientIds`, then subscribes to each `/patients/{patientId}` doc.
  Stream<List<PatientModel>> getLinkedPatientsStream(String caretakerId) {
    debugPrint('[PatientService] caretakerId=$caretakerId');

    final userRef = _db.collection(_colUsers).doc(caretakerId);
    return userRef.snapshots().asyncExpand((snap) {
      final data = snap.data();
      final ids = List<String>.from(data?['patientIds'] ?? const []);

      debugPrint('[PatientService] patientIds(${ids.length})');

      if (ids.isEmpty) {
        return Stream.value(<PatientModel>[]);
      }

      // Subscribe to each patient document for realtime updates (no collection query).
      final controller = StreamController<List<PatientModel>>();
      final subs = <StreamSubscription>[];
      final byId = <String, PatientModel>{};

      void emit() {
        final list = byId.values.toList();
        list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        debugPrint('[PatientService] fetchedPatientCount=${list.length}');
        controller.add(list);
      }

      for (final id in ids) {
        final sub = _db.collection(_colPatients).doc(id).snapshots().listen(
          (docSnap) {
            if (docSnap.exists && docSnap.data() != null) {
              byId[id] = PatientModel.fromDoc(docSnap);
            } else {
              byId.remove(id);
            }
            emit();
          },
          onError: (e) {
            // Surface as empty list rather than failing the entire stream.
            debugPrint('[PatientService] patient doc error: $e');
          },
        );
        subs.add(sub);
      }

      controller.onCancel = () async {
        for (final s in subs) {
          await s.cancel();
        }
        await controller.close();
      };

      return controller.stream;
    });
  }

  /// Add a new patient and link to caretaker
  Future<String> addPatient(PatientModel patient) async {
    final ref = await _db.collection(_colPatients).add(patient.toMap());
    return ref.id;
  }

  /// Delete a patient record
  Future<void> deletePatient(String patientId) async {
    await _db.collection(_colPatients).doc(patientId).delete();
  }

  /// Find a patient user by email. Returns their uid if found as a patient role, null otherwise.
  Future<String?> findPatientByEmail(String email) async {
    final query = await _db
        .collection(_colUsers)
        .where('email', isEqualTo: email.trim().toLowerCase())
        .where('role', isEqualTo: 'patient')
        .limit(1)
        .get();
    if (query.docs.isEmpty) return null;
    return query.docs.first.id;
  }

  /// Link an existing patient (by their uid) to a caretaker using arrayUnion.
  Future<void> linkPatientByEmail({
    required String patientUid,
    required String caretakerId,
  }) async {
    final userDoc = await _db.collection(_colUsers).doc(patientUid).get();
    final userData = userDoc.data();

    final batch = _db.batch();

    // 1) Ensure patients/{patientUid} exists (for medical data screens)
    final patientRef = _db.collection(_colPatients).doc(patientUid);
    batch.set(patientRef, {
      'patientId': patientUid,
      // Back-compat: keep caretakerIds on patients doc too.
      'caretakerIds': FieldValue.arrayUnion([caretakerId]),
      if (userData != null) ...{
        if (userData['name'] != null) 'name': userData['name'],
        if (userData['email'] != null) 'email': userData['email'],
      },
    }, SetOptions(merge: true));

    // 2) Update caretaker's users/{caretakerId}.patientIds
    final caretakerUserRef = _db.collection(_colUsers).doc(caretakerId);
    batch.set(caretakerUserRef, {
      'patientIds': FieldValue.arrayUnion([patientUid]),
    }, SetOptions(merge: true));

    // 3) Update patient's users/{patientUid}.caretakerIds (rules source of truth)
    final patientUserRef = _db.collection(_colUsers).doc(patientUid);
    batch.set(patientUserRef, {
      'caretakerIds': FieldValue.arrayUnion([caretakerId]),
    }, SetOptions(merge: true));

    await batch.commit();
  }

  /// Link a patient to a caretaker (legacy method kept for compatibility)
  Future<void> linkPatientToCaretaker({
    required String patientId,
    required String caretakerId,
  }) async {
    await _db.collection(_colPatients).doc(patientId).set({
      'patientId': patientId,
      'caretakerIds': FieldValue.arrayUnion([caretakerId]),
    }, SetOptions(merge: true));
  }

  /// Returns true iff `caretakerId` is linked to `patientId` via patients/{patientId}.caretakerIds.
  Future<bool> isCaretakerLinked({
    required String patientId,
    required String caretakerId,
  }) async {
    // Source of truth: users/{patientId}.caretakerIds
    final doc = await _db.collection(_colUsers).doc(patientId).get();
    if (!doc.exists || doc.data() == null) return false;
    final data = doc.data() as Map<String, dynamic>;
    final ids = List<String>.from(data['caretakerIds'] ?? const []);
    return ids.contains(caretakerId);
  }
}
