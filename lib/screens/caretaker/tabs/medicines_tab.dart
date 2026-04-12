import 'package:flutter/material.dart';

import '../../../models/medicine_model.dart';
import '../../../models/adherence_log_model.dart';
import '../../../services/medicine_service.dart';
import '../../../services/adherence_service.dart';
import '../../../widgets/glass_components.dart';
import '../../app_theme.dart';

/// Caretaker Medicines tab — shows all patients' medicines and today's adherence.
/// Receives the patientId to filter medicines for the selected patient.
class CaretakerMedicinesTab extends StatelessWidget {
  const CaretakerMedicinesTab({super.key, this.patientId});

  final String? patientId;

  @override
  Widget build(BuildContext context) {
    if (patientId == null || patientId!.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Medicines',
              style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: -0.5)),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: Center(
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
                      color: AppColors.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.medication_outlined,
                        size: 60, color: AppColors.primary),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Select a Patient First',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Go to the Patients tab and select a patient to view their medicines.',
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
        ),
      );
    }

    return _PatientMedicinesView(patientId: patientId!);
  }
}

// ─── Patient Medicines View ───────────────────────────────────────────────────

class _PatientMedicinesView extends StatelessWidget {
  final String patientId;
  const _PatientMedicinesView({required this.patientId});

  @override
  Widget build(BuildContext context) {
    final medService = MedicineService();
    final adhService = AdherenceService();

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Medicines',
            style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: -0.5)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: StreamBuilder<List<MedicineModel>>(
        stream: medService.getMedicinesStream(patientId),
        builder: (context, medSnap) {
          if (medSnap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (medSnap.hasError) {
            return Center(child: Text('Error: ${medSnap.error}'));
          }
          final meds = medSnap.data ?? [];
          if (meds.isEmpty) {
            return _emptyMedState(context);
          }

          return StreamBuilder<List<AdherenceLogModel>>(
            stream: adhService.getRecentLogs(patientId),
            builder: (context, logSnap) {
              final logs = logSnap.data ?? [];
              final today = DateTime.now();

              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
                itemCount: meds.length,
                itemBuilder: (_, i) {
                  final med = meds[i];
                  final todayLogs = logs.where((l) {
                    final ts = l.timestamp;
                    return l.medicineId == med.id &&
                        ts.year == today.year &&
                        ts.month == today.month &&
                        ts.day == today.day;
                  }).toList();
                  return _MedicineCard(med: med, todayLogs: todayLogs);
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _emptyMedState(BuildContext context) {
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
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.medication_liquid_rounded,
                    size: 60, color: AppColors.primary),
              ),
              const SizedBox(height: 24),
              const Text(
                'No Medicines Yet',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'No medicines assigned to this patient yet.',
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

// ─── Medicine Card ────────────────────────────────────────────────────────────

class _MedicineCard extends StatelessWidget {
  final MedicineModel med;
  final List<AdherenceLogModel> todayLogs;

  const _MedicineCard({required this.med, required this.todayLogs});

  @override
  Widget build(BuildContext context) {
    final isTaken = todayLogs.any((l) => l.taken);
    final isMissed = !isTaken && todayLogs.any((l) => !l.taken);

    Color statusColor;
    IconData statusIcon;
    String statusText;

    if (isTaken) {
      statusColor = Colors.teal;
      statusIcon = Icons.check_circle_rounded;
      statusText = 'Taken';
    } else if (isMissed) {
      statusColor = Colors.redAccent;
      statusIcon = Icons.cancel_rounded;
      statusText = 'Missed';
    } else {
      statusColor = AppColors.warning;
      statusIcon = Icons.schedule_rounded;
      statusText = 'Pending';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.medication_rounded, color: statusColor, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    med.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${med.dosage} · ${med.timings.join(", ")}',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary.withOpacity(0.8),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            StatusPill(
              label: statusText,
              icon: statusIcon,
              baseColor: statusColor,
            ),
          ],
        ),
      ),
    );
  }
}
