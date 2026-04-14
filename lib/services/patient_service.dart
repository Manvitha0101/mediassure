import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/patient_model.dart';

// ─── Custom error types for clean UI messaging ─────────────────────────────────

class LinkError implements Exception {
  final String message;
  const LinkError(this.message);
  @override
  String toString() => message;
}

class UserNotFoundError extends LinkError {
  const UserNotFoundError() : super('No account found with this email.');
}

class NotAPatientError extends LinkError {
  const NotAPatientError() : super('This email belongs to a Caretaker or Doctor — not a Patient.');
}

class AlreadyLinkedError extends LinkError {
  const AlreadyLinkedError() : super('This patient is already linked to your account.');
}

class SelfLinkError extends LinkError {
  const SelfLinkError() : super('You cannot link yourself as a patient.');
}

class PermissionDeniedError extends LinkError {
  const PermissionDeniedError() : super('Permission denied. Please ensure your Firebase security rules are updated.');
}

// ─── PatientService ───────────────────────────────────────────────────────────

class PatientService {
  final _db = FirebaseFirestore.instance;

  // ── Phase 1: Link patient by email ─────────────────────────────────────────

  /// Links a registered Patient account to this caretaker by email.
  ///
  /// Firestore batch (atomic):
  ///   1. Creates/updates /patients/{patientUid} with caretakerId + linkStatus
  ///   2. arrayUnion patientUid into /users/{caretakerId}.patientIds
  ///   3. Sets caretakerId in /users/{patientUid}
  ///
  /// Structured for future approval flow: linkStatus is "active" now;
  /// can be changed to "pending" + require patient confirmation later.
  Future<void> linkPatientByEmail(String caretakerId, String patientEmail) async {
    final email = patientEmail.trim().toLowerCase();

    // Guard: can't link yourself
    final selfEmail = FirebaseAuth.instance.currentUser?.email?.toLowerCase();
    if (selfEmail == email) throw const SelfLinkError();

    // Step 1: Look up /users by email
    final usersSnap = await _db
        .collection('users')
        .where('email', isEqualTo: email)
        .limit(1)
        .get();

    if (usersSnap.docs.isEmpty) throw const UserNotFoundError();

    final userDoc = usersSnap.docs.first;
    final userData = userDoc.data();
    final patientUid = userDoc.id;
    final role = userData['role'] ?? '';

    // Step 2: Validate role
    if (role != 'patient') throw const NotAPatientError();

    // Step 3: Check not already linked
    final caretakerDoc = await _db.collection('users').doc(caretakerId).get();
    final existingIds = List<String>.from(
        (caretakerDoc.data() as Map<String, dynamic>?)?['patientIds'] ?? []);
    if (existingIds.contains(patientUid)) throw const AlreadyLinkedError();

    // Step 4: Atomic batch write
    final batch = _db.batch();

    // 4a. Create /patients/{patientUid} — operational link record
    final patientRef = _db.collection('patients').doc(patientUid);
    batch.set(
      patientRef,
      PatientModel(
        patientId: patientUid,
        caretakerId: caretakerId,
        linkStatus: 'active', // future: 'pending' for approval flow
      ).toMap(),
      SetOptions(merge: true), // safe if doc already exists
    );

    // 4b. Add patientUid to caretaker's patientIds
    final caretakerRef = _db.collection('users').doc(caretakerId);
    batch.update(caretakerRef, {
      'patientIds': FieldValue.arrayUnion([patientUid]),
    });

    // 4c. Set caretakerId on the patient's user record
    final patientUserRef = _db.collection('users').doc(patientUid);
    batch.update(patientUserRef, {'caretakerId': caretakerId});

    try {
      await batch.commit();
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        throw const PermissionDeniedError();
      }
      rethrow;
    } catch (e) {
      rethrow;
    }

    // ── Debug verification logs ─────────────────────────────────────────────
    if (kDebugMode) {
      final updatedCaretaker = await _db.collection('users').doc(caretakerId).get();
      final updatedPatient = await _db.collection('users').doc(patientUid).get();
      debugPrint('✅ [LinkPatient] Success!');
      debugPrint('   caretaker.patientIds: ${updatedCaretaker.data()?['patientIds']}');
      debugPrint('   patient.caretakerId : ${updatedPatient.data()?['caretakerId']}');
      debugPrint('   patient name        : ${updatedPatient.data()?['name']}');
      debugPrint('   patient email       : ${updatedPatient.data()?['email']}');
    }
  }

  // ── Phase 2: Stream of linked patients for the dashboard ───────────────────

  /// Two-step stream:
  ///   1. Listen to /users/{caretakerId} for real-time patientIds changes
  ///   2. For each UID, fetch identity from /users AND link data from /patients
  ///   3. Skips missing/deleted docs silently (null-safe)
  ///   4. Emits [] immediately when patientIds is empty
  Stream<List<LinkedPatient>> getLinkedPatientsStream(String caretakerId) {
    return _db
        .collection('users')
        .doc(caretakerId)
        .snapshots()
        .asyncMap((caretakerSnap) async {
      if (!caretakerSnap.exists) return <LinkedPatient>[];

      final data = caretakerSnap.data() as Map<String, dynamic>?;
      final patientIds = List<String>.from(data?['patientIds'] ?? []);

      if (patientIds.isEmpty) return <LinkedPatient>[];

      // Fetch all patient user docs + patient link docs in parallel
      final futures = patientIds.map((uid) async {
        try {
          final userFuture = _db.collection('users').doc(uid).get();
          final linkFuture = _db.collection('patients').doc(uid).get();

          final results = await Future.wait([userFuture, linkFuture]);
          final userDoc = results[0];
          final linkDoc = results[1];

          // Skip silently if either doc is missing/deleted
          if (!userDoc.exists) {
            debugPrint('⚠️ [LinkedPatients] /users/$uid not found — skipping');
            return null;
          }

          final userData = userDoc.data() as Map<String, dynamic>;
          final linkData = linkDoc.exists
              ? (linkDoc.data() as Map<String, dynamic>)
              : <String, dynamic>{};

          return LinkedPatient(
            uid: uid,
            name: userData['name'] ?? 'Unknown',
            email: userData['email'] ?? '',
            caretakerId: linkData['caretakerId'] ?? caretakerId,
            linkStatus: linkData['linkStatus'] ?? 'active',
          );
        } catch (e) {
          debugPrint('⚠️ [LinkedPatients] Error fetching uid=$uid: $e');
          return null;
        }
      });

      final results = await Future.wait(futures);
      // Filter out nulls (missing/errored docs)
      return results.whereType<LinkedPatient>().toList();
    });
  }

  /// Delete a patient link (unlinks from caretaker)
  Future<void> unlinkPatient(String caretakerId, String patientUid) async {
    final batch = _db.batch();

    batch.update(_db.collection('users').doc(caretakerId), {
      'patientIds': FieldValue.arrayRemove([patientUid]),
    });
    batch.update(_db.collection('users').doc(patientUid), {
      'caretakerId': FieldValue.delete(),
    });
    batch.delete(_db.collection('patients').doc(patientUid));

    await batch.commit();
    debugPrint('🔗 [UnlinkPatient] Removed $patientUid from caretaker $caretakerId');
  }
}
