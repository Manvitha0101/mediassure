import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'dart:io';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/adherence_log_model.dart';
import 'image_picker_service.dart';
import 'patient_service.dart';
import 'notification_service.dart';

class AdherenceService {
  final _db = FirebaseFirestore.instance;
  final _imagePicker = ImagePickerService();
  final _patientService = PatientService();
  static const String _colAdherenceLogs = 'adherenceLogs';
  static const String _colPatientLogs = 'patient_logs';

  /// Stream of recent adherence logs for a given patient (last 30 days)
  Stream<List<AdherenceLogModel>> getRecentLogs(String patientId) {
    return _db
        .collection(_colAdherenceLogs)
        .where('patientId', isEqualTo: patientId)
        .snapshots()
        .map((snap) {
          // Avoid composite-index requirement by sorting client-side.
          final cutoff = DateTime.now().subtract(const Duration(days: 30));
          final all = snap.docs
              .map((doc) => AdherenceLogModel.fromMap(doc.data(), doc.id, includeImage: false))
              .where((l) => l.timestamp.isAfter(cutoff))
              .toList();
          all.sort((a, b) => b.timestamp.compareTo(a.timestamp));
          return all;
        });
  }

  /// Logs for a specific day (00:00..23:59) for adherence calendar views.
  Stream<List<AdherenceLogModel>> getLogsForDay(String patientId, DateTime day) {
    final start = DateTime(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));
    return _db
        .collection(_colAdherenceLogs)
        .where('patientId', isEqualTo: patientId)
        .snapshots()
        .map((snap) {
          // Avoid composite-index requirement by filtering client-side.
          final all = snap.docs
              .map((doc) => AdherenceLogModel.fromMap(doc.data(), doc.id, includeImage: false))
              .where((l) => !l.timestamp.isBefore(start) && l.timestamp.isBefore(end))
              .toList();
          all.sort((a, b) => b.timestamp.compareTo(a.timestamp));
          return all;
        });
  }

  Future<void> logAdherenceStrict({
    required String patientId,
    required String medicineId,
    required String scheduledTime,
    required bool taken,
    String? medicineName,
    String? caretakerId,
    String? caretakerName,
  }) async {

    final log = AdherenceLogModel(
      id: '',
      patientId: patientId,
      medicineId: medicineId,
      caretakerId: caretakerId ?? '',
      caretakerName: caretakerName ?? '',
      scheduledTime: scheduledTime,
      timestamp: DateTime.now(),
      taken: taken,
    );

    await _db.collection(_colAdherenceLogs).add(log.toMap());

    // Notify caretakers if a dose was missed — non-blocking, safe failure
    if (!taken) {
      _notifyMissedDose(
        patientId: patientId,
        medicineName: medicineName ?? 'a medicine',
        scheduledTime: scheduledTime,
      );
    }

    // Also create a patient log entry automatically
    if (medicineName != null &&
        caretakerId != null &&
        caretakerName != null &&
        taken == true) {
      final now = DateTime.now();
      final String amPm = now.hour >= 12 ? 'PM' : 'AM';
      final int hour12 =
          now.hour > 12 ? now.hour - 12 : (now.hour == 0 ? 12 : now.hour);
      final String timeStr =
          '$hour12:${now.minute.toString().padLeft(2, '0')} $amPm';

      final logMessage = "$medicineName given at $timeStr";

      final patientLogRef = _db.collection(_colPatientLogs).doc();
      await patientLogRef.set({
        'patientId': patientId,
        'message': logMessage,
        'caretakerId': caretakerId,
        'caretakerName': caretakerName,
        'timestamp': FieldValue.serverTimestamp(),
      });
    }
  }

  // ── Missed-dose notification ─────────────────────────────────────────────

  /// Sends a local notification on the current device to alert about a missed
  /// dose. Wrapped in try/catch — never throws, never blocks callers.
  void _notifyMissedDose({
    required String patientId,
    required String medicineName,
    required String scheduledTime,
  }) {
    _doNotifyMissedDose(
      patientId: patientId,
      medicineName: medicineName,
      scheduledTime: scheduledTime,
    ).catchError((e) {
      debugPrint('Missed-dose notification failed (non-fatal): $e');
    });
  }

  Future<void> _doNotifyMissedDose({
    required String patientId,
    required String medicineName,
    required String scheduledTime,
  }) async {
    // Show an immediate local notification AND look up caretaker FCM tokens.
    // This method never throws — errors are caught inside notifyMissedDoseToCaretakers.
    await NotificationService.instance.notifyMissedDoseToCaretakers(
      patientId: patientId,
      medicineName: medicineName,
      scheduledTime: scheduledTime,
    );
  }

  /// Caretaker-only: capture proof photo, drop it, then write
  /// `adherenceLogs`.
  Future<void> markTakenWithCamera({
    required String patientId,
    required String medicineId,
    required String medicineName,
    required String caretakerId,
    required String caretakerName,
    required String scheduledTime,
  }) async {
    debugPrint('[markTakenWithCamera] START — med=$medicineName patient=$patientId');

    final linked = await _patientService.isCaretakerLinked(
      patientId: patientId,
      caretakerId: caretakerId,
    );
    if (!linked) {
      debugPrint('[markTakenWithCamera] ABORT — caretaker not linked');
      throw Exception('Not linked to this patient.');
    }
    debugPrint('[markTakenWithCamera] link check passed, opening camera...');

    // ── STATE PRESERVATION FOR ANDROID BACKGROUND KILL ──
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('pending_adherence_patientId', patientId);
    await prefs.setString('pending_adherence_medicineId', medicineId);
    await prefs.setString('pending_adherence_medicineName', medicineName);
    await prefs.setString('pending_adherence_caretakerId', caretakerId);
    await prefs.setString('pending_adherence_caretakerName', caretakerName);
    await prefs.setString('pending_adherence_scheduledTime', scheduledTime);

    File? file = await _imagePicker.pickFromCamera();
    
    // If we reach here, the app WAS NOT killed by the OS.
    await _clearPendingAdherence(prefs);

    if (file == null) {
      debugPrint('[markTakenWithCamera] ABORT — camera returned null');
      throw Exception('Image is required to mark as taken.');
    }

    // Free memory immediately - we only care that they took a picture, we don't store it
    file = null;
    debugPrint("Image captured but not stored, marking as taken");

    await logAdherenceStrict(
      patientId: patientId,
      medicineId: medicineId,
      medicineName: medicineName,
      caretakerId: caretakerId,
      caretakerName: caretakerName,
      scheduledTime: scheduledTime,
      taken: true,
    );
    debugPrint('[markTakenWithCamera] SUCCESS — adherence log written');
  }

  // ── STATE RESTORATION METHODS ──

  Future<void> _clearPendingAdherence(SharedPreferences prefs) async {
    await prefs.remove('pending_adherence_patientId');
    await prefs.remove('pending_adherence_medicineId');
    await prefs.remove('pending_adherence_medicineName');
    await prefs.remove('pending_adherence_caretakerId');
    await prefs.remove('pending_adherence_caretakerName');
    await prefs.remove('pending_adherence_scheduledTime');
  }

  /// Checks if the app was killed while the camera was open and restores state.
  Future<void> recoverLostCameraData() async {
    final prefs = await SharedPreferences.getInstance();
    final patientId = prefs.getString('pending_adherence_patientId');
    
    if (patientId == null) return; // No pending adherence
    
    debugPrint('[recoverLostCameraData] Found pending adherence for patient: $patientId');
    
    final response = await _imagePicker.retrieveLostData();
    
    // If response is empty, it means either camera didn't return anything or it failed.
    // However, since we just need "momentary verification", if we have a file, it's a success.
    if (!response.isEmpty && response.file != null) {
      debugPrint('[recoverLostCameraData] Recovered lost image. Marking as taken.');
      
      final medicineId = prefs.getString('pending_adherence_medicineId') ?? '';
      final medicineName = prefs.getString('pending_adherence_medicineName') ?? 'Unknown';
      final caretakerId = prefs.getString('pending_adherence_caretakerId') ?? '';
      final caretakerName = prefs.getString('pending_adherence_caretakerName') ?? '';
      final scheduledTime = prefs.getString('pending_adherence_scheduledTime') ?? '';

      await logAdherenceStrict(
        patientId: patientId,
        medicineId: medicineId,
        medicineName: medicineName,
        caretakerId: caretakerId,
        caretakerName: caretakerName,
        scheduledTime: scheduledTime,
        taken: true,
      );
      debugPrint('[recoverLostCameraData] SUCCESS — restored adherence log written');
    } else {
      debugPrint('[recoverLostCameraData] Lost data response was empty or null.');
    }

    // Always clear the pending state after attempting recovery
    await _clearPendingAdherence(prefs);
  }
}
