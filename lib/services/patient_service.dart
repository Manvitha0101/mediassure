import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import '../models/patient_model.dart';
import '../models/user_role_model.dart';

class LinkPatientException implements Exception {
  final String code;
  final String message;

  const LinkPatientException(this.code, this.message);

  @override
  String toString() => message;
}

class PatientService {
  final _db = FirebaseFirestore.instance;
  static const String _colUsers = 'users';
  static const String _colPatients = 'patients';

  /// Backward-compatible alias (older UI calls).
  Stream<List<PatientModel>> getPatientsByCaretaker(String caretakerId) {
    return getLinkedPatientsStream(caretakerId);
  }

  /// Role-agnostic linked patients stream for caretaker/doctor.
  Stream<List<PatientModel>> getLinkedPatientsStreamForUser(String userId) {
    return getLinkedPatientsStream(userId);
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

  /// Find a patient user by email. Returns uid if found, null otherwise.
  Future<String?> findPatientByEmail(String email) async {
    final query = await _db
        .collection(_colUsers)
        .where('email', isEqualTo: email.trim().toLowerCase())
        .limit(1)
        .get();
    if (query.docs.isEmpty) return null;
    final data = query.docs.first.data();
    final role = (data['role'] ?? '').toString().toLowerCase();
    if (role != UserRole.patient.name) return null;
    return query.docs.first.id;
  }

  /// Link patient to caretaker using validated transactional writes.
  Future<void> linkPatientByEmail({
    required String patientUid,
    required String caretakerId,
  }) async {
    return _linkPatientToActor(
      patientUid: patientUid,
      actorId: caretakerId,
      actorRole: UserRole.caretaker,
    );
  }

  /// Link patient to doctor using validated transactional writes.
  Future<void> linkPatientToDoctor({
    required String patientUid,
    required String doctorId,
  }) async {
    return _linkPatientToActor(
      patientUid: patientUid,
      actorId: doctorId,
      actorRole: UserRole.doctor,
    );
  }

  /// Link a patient to a caretaker (legacy method kept for compatibility)
  Future<void> linkPatientToCaretaker({
    required String patientId,
    required String caretakerId,
  }) async {
    await linkPatientByEmail(patientUid: patientId, caretakerId: caretakerId);
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

  Future<void> _linkPatientToActor({
    required String patientUid,
    required String actorId,
    required UserRole actorRole,
  }) async {
    if (actorId.isEmpty) {
      throw const LinkPatientException(
        'not_authenticated',
        'You must be logged in to link a patient.',
      );
    }

    if (actorRole != UserRole.caretaker && actorRole != UserRole.doctor) {
      throw const LinkPatientException(
        'invalid_actor_role',
        'Only caretaker or doctor can link a patient.',
      );
    }

    final patientRef = _db.collection(_colUsers).doc(patientUid);
    final actorRef = _db.collection(_colUsers).doc(actorId);
    final patientProfileRef = _db.collection(_colPatients).doc(patientUid);

    await _db.runTransaction((tx) async {
      final patientUserSnap = await tx.get(patientRef);
      final actorUserSnap = await tx.get(actorRef);

      if (!patientUserSnap.exists || patientUserSnap.data() == null) {
        throw const LinkPatientException(
          'user_not_found',
          'No user found for the selected patient.',
        );
      }

      if (!actorUserSnap.exists || actorUserSnap.data() == null) {
        throw const LinkPatientException(
          'actor_not_found',
          'Current user record was not found.',
        );
      }

      final patientUser = patientUserSnap.data()!;
      final actorUser = actorUserSnap.data()!;
      final targetRole = (patientUser['role'] ?? '').toString().toLowerCase();
      if (targetRole != UserRole.patient.name) {
        throw const LinkPatientException(
          'target_not_patient',
          'This user is not registered as a patient.',
        );
      }
      
      final profileCompleted = patientUser['profileCompleted'] == true;
      if (!profileCompleted) {
        throw const LinkPatientException(
          'profile_incomplete',
          'This patient has not completed their profile setup. Ask them to login and complete it first.',
        );
      }

      final currentActorRole = (actorUser['role'] ?? '').toString().toLowerCase();
      if (currentActorRole != actorRole.name) {
        throw LinkPatientException(
          'actor_role_mismatch',
          'Only ${actorRole.name} accounts can perform this link.',
        );
      }

      final actorPatientIds = List<String>.from(actorUser['patientIds'] ?? const []);
      final patientCaretakerIds =
          List<String>.from(patientUser['caretakerIds'] ?? const []);
      final patientDoctorIds = List<String>.from(patientUser['doctorIds'] ?? const []);

      final alreadyLinked = actorRole == UserRole.caretaker
          ? patientCaretakerIds.contains(actorId)
          : patientDoctorIds.contains(actorId);

      if (alreadyLinked || actorPatientIds.contains(patientUid)) {
        throw const LinkPatientException(
          'already_linked',
          'This patient is already linked.',
        );
      }

      // users/{actor}.patientIds supports realtime linked-patient list for
      // both caretaker and doctor tabs.
      tx.set(actorRef, {
        'patientIds': FieldValue.arrayUnion([patientUid]),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      final linkedKey = actorRole == UserRole.caretaker ? 'caretakerIds' : 'doctorIds';
      tx.set(patientRef, {
        linkedKey: FieldValue.arrayUnion([actorId]),
      }, SetOptions(merge: true));

      // We ONLY update the profile record; we cannot read it beforehand due to rules.
      // Since profileCompleted is true, we know the document exists.
      tx.set(patientProfileRef, {
        'patientId': patientUid,
        linkedKey: FieldValue.arrayUnion([actorId]),
        if (patientUser['name'] != null) 'name': patientUser['name'],
        if (patientUser['email'] != null) 'email': patientUser['email'],
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    });
  }
}
