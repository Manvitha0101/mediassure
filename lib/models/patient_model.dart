import 'package:cloud_firestore/cloud_firestore.dart';

/// Stored in /patients/{patientUid}
/// This is the OPERATIONAL record — only link metadata.
/// Identity data (name, email) is fetched from /users/{patientUid} at runtime.
class PatientModel {
  /// UID of the patient (same as /users/{uid})
  final String patientId;

  /// UID of the caretaker who linked this patient
  final String caretakerId;

  /// "active" | "pending" — future-proofed for approval flow
  final String linkStatus;

  /// When the link was created
  final DateTime? linkedAt;

  PatientModel({
    required this.patientId,
    required this.caretakerId,
    this.linkStatus = 'active',
    this.linkedAt,
  });

  Map<String, dynamic> toMap() => {
        'caretakerId': caretakerId,
        'linkStatus': linkStatus,
        'linkedAt': FieldValue.serverTimestamp(),
      };

  factory PatientModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PatientModel(
      patientId: doc.id,
      caretakerId: data['caretakerId'] ?? '',
      linkStatus: data['linkStatus'] ?? 'active',
      linkedAt: data['linkedAt'] != null
          ? (data['linkedAt'] as Timestamp).toDate()
          : null,
    );
  }
}

/// View-model that merges /users identity + /patients link data.
/// Used in the caretaker dashboard — no raw data duplication.
class LinkedPatient {
  final String uid;
  final String name;
  final String email;
  final String caretakerId;
  final String linkStatus;

  LinkedPatient({
    required this.uid,
    required this.name,
    required this.email,
    required this.caretakerId,
    required this.linkStatus,
  });

  /// Initials for avatar (up to 2 chars)
  String get initials => name.trim().isNotEmpty
      ? name.trim().split(' ').map((w) => w[0]).take(2).join().toUpperCase()
      : '?';
}
