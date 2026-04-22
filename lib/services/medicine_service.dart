import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/medicine_model.dart';
import 'notification_service.dart';

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

  /// Add a new medicine and re-sync local reminders for that patient.
  Future<String> addMedicine(MedicineModel medicine) async {
    final ref = await _db.collection('medicines').add(medicine.toMap());
    _syncRemindersFor(medicine.patientId); // non-blocking
    return ref.id;
  }

  /// Update an existing medicine and re-sync local reminders.
  Future<void> updateMedicine(MedicineModel medicine) async {
    await _db.collection('medicines').doc(medicine.id).update(medicine.toMap());
    _syncRemindersFor(medicine.patientId); // non-blocking
  }

  /// Delete a medicine and re-sync local reminders.
  Future<void> deleteMedicine(String id) async {
    // Fetch patientId before deleting so we can re-sync
    String? patientId;
    try {
      final doc = await _db.collection('medicines').doc(id).get();
      patientId = doc.data()?['patientId'] as String?;
    } catch (_) {}

    await _db.collection('medicines').doc(id).delete();

    if (patientId != null && patientId.isNotEmpty) {
      _syncRemindersFor(patientId); // non-blocking
    }
  }

  // ── Internal helpers ────────────────────────────────────────────────────────

  /// Fetch all active medicines for [patientId] and re-schedule local reminders.
  /// Non-blocking: errors are caught and printed so they never affect callers.
  void _syncRemindersFor(String patientId) {
    _doSync(patientId).catchError((e) {
      debugPrint('MedicineService: reminder sync failed for $patientId – $e');
    });
  }

  Future<void> _doSync(String patientId) async {
    final snap = await _db
        .collection('medicines')
        .where('patientId', isEqualTo: patientId)
        .get();

    final now = DateTime.now();
    final meds = snap.docs
        .map((d) => MedicineModel.fromMap(d.id, d.data()))
        .where((m) =>
            m.isActive && _isDateInRange(now, m.startDate, m.endDate))
        .toList();

    await NotificationService.instance.syncMedicineReminders(
      scopeKey: 'patient:$patientId',
      medicines: meds,
      titlePrefix: 'Medicine',
    );
  }

  bool _isDateInRange(DateTime date, DateTime start, DateTime end) {
    final d = DateTime(date.year, date.month, date.day);
    final s = DateTime(start.year, start.month, start.day);
    final e = DateTime(end.year, end.month, end.day);
    return d.isAfter(s.subtract(const Duration(days: 1))) &&
        d.isBefore(e.add(const Duration(days: 1)));
  }
}