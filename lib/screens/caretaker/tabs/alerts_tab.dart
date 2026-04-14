import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import '../../../models/patient_model.dart';
import '../../../models/medicine_model.dart';
import '../../../models/adherence_log_model.dart';
import '../../../services/patient_service.dart';
import '../../../services/medicine_service.dart';
import '../../../services/adherence_service.dart';
import '../../../widgets/glass_components.dart';
import '../../app_theme.dart';

/// Alerts tab — shows missed medicines across all linked patients today
class CaretakerAlertsTab extends StatelessWidget {
  const CaretakerAlertsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final caretakerId = FirebaseAuth.instance.currentUser?.uid ?? '';
    final patientService = PatientService();

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text(
          'Alerts',
          style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: -0.5),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: caretakerId.isEmpty
          ? const Center(child: Text('Not logged in'))
          : StreamBuilder<List<PatientModel>>(
              // Uses the new stream from /users.patientIds
              stream: patientService.getPatientsByCaretaker(caretakerId),
              builder: (context, patientSnap) {
                if (patientSnap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final patients = patientSnap.data ?? [];
                if (patients.isEmpty) {
                  return _buildNoPatients();
                }
                return _MissedAlertsList(patients: patients);
              },
            ),
    );
  }

  Widget _buildNoPatients() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: GlassCard(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_outline_rounded,
                    size: 60, color: Colors.green),
              ),
              const SizedBox(height: 24),
              const Text(
                'All Clear!',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'No patients linked yet. Add patients from the Patients tab.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary.withOpacity(0.8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Missed Alerts List ───────────────────────────────────────────────────────

class _MissedAlertsList extends StatelessWidget {
  final List<PatientModel> patients;
  const _MissedAlertsList({required this.patients});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
      itemCount: patients.length,
      itemBuilder: (_, i) => _PatientAlertsSection(patient: patients[i]),
    );
  }
}

class _PatientAlertsSection extends StatelessWidget {
  final PatientModel patient;
  const _PatientAlertsSection({required this.patient});

  @override
  Widget build(BuildContext context) {
    final medService = MedicineService();
    final adhService = AdherenceService();
    final today = DateTime.now();
    // ignore: unused_local_variable
    final timeFormat = DateFormat('h:mm a');

    return StreamBuilder<List<MedicineModel>>(
      stream: medService.getMedicinesStream(patient.patientId),
      builder: (context, medSnap) {
        final meds = medSnap.data ?? [];
        if (meds.isEmpty) return const SizedBox.shrink();

        return StreamBuilder<List<AdherenceLogModel>>(
          stream: adhService.getRecentLogs(patient.patientId),
          builder: (context, logSnap) {
            final logs = logSnap.data ?? [];

            // Build missed alerts: timings that have a "missed" log today
            final alerts = <_AlertItem>[];
            for (final med in meds) {
              for (final timing in med.timings) {
                final todayLog = logs.firstWhere(
                  (l) =>
                      l.medicineId == med.id &&
                      l.scheduledTime == timing &&
                      l.timestamp.year == today.year &&
                      l.timestamp.month == today.month &&
                      l.timestamp.day == today.day,
                  orElse: () => AdherenceLogModel(
                    id: '',
                    patientId: patient.patientId,
                    medicineId: med.id,
                    caretakerId: '',
                    caretakerName: '',
                    scheduledTime: timing,
                    timestamp: today,
                    taken: false,
                  ),
                );
                if (!todayLog.taken) {
                  alerts.add(_AlertItem(
                    medicineName: med.name,
                    dosage: med.dosage,
                    timing: timing,
                    isMissed: todayLog.id.isNotEmpty,
                  ));
                }
              }
            }

            if (alerts.isEmpty) return const SizedBox.shrink();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 10, top: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.primary, AppColors.accent],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Text(
                            patient.name.isNotEmpty
                                ? patient.name[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          patient.name,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.danger.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${alerts.length} alert${alerts.length > 1 ? 's' : ''}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.danger,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                ...alerts.map((a) => _AlertCard(alert: a)),
                const SizedBox(height: 8),
              ],
            );
          },
        );
      },
    );
  }
}

// ─── Alert Item Model ─────────────────────────────────────────────────────────

class _AlertItem {
  final String medicineName;
  final String dosage;
  final String timing;
  final bool isMissed; // true = confirmed missed, false = not yet marked

  const _AlertItem({
    required this.medicineName,
    required this.dosage,
    required this.timing,
    required this.isMissed,
  });
}

// ─── Alert Card ───────────────────────────────────────────────────────────────

class _AlertCard extends StatelessWidget {
  final _AlertItem alert;
  const _AlertCard({required this.alert});

  @override
  Widget build(BuildContext context) {
    final color = alert.isMissed ? AppColors.danger : AppColors.warning;
    final icon = alert.isMissed
        ? Icons.cancel_rounded
        : Icons.schedule_rounded;
    final label = alert.isMissed ? 'Missed' : 'Pending';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    alert.medicineName,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${alert.dosage} · ${alert.timing}',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary.withOpacity(0.8),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            StatusPill(label: label, icon: icon, baseColor: color),
          ],
        ),
      ),
    );
  }
}
