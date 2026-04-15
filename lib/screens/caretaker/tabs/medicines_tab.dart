import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../models/medicine_model.dart';
import '../../../models/adherence_log_model.dart';
import '../../../services/medicine_service.dart';
import '../../../services/adherence_service.dart';
import '../../../services/notification_service.dart';
import '../../../widgets/glass_components.dart';
import '../../app_theme.dart';
import '../../add_medicine_screen.dart';
import '../patient_logs_screen.dart';
import '../../chat_screen.dart';
import '../../../models/user_role_model.dart';
import '../../../services/auth_service.dart';
import '../../../models/patient_log_model.dart';
import '../../../services/patient_log_service.dart';

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
    final logService = PatientLogService();
    final caretakerId = FirebaseAuth.instance.currentUser?.uid ?? '';

    return FutureBuilder<UserModel?>(
      future: AuthService().getUserRole(caretakerId),
      builder: (context, userSnap) {
        if (userSnap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Colors.transparent,
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final caretakerModel = userSnap.data;
        if (caretakerModel == null) {
          return const Scaffold(
            backgroundColor: Colors.transparent,
            body: Center(child: Text('Error loading caretaker')),
          );
        }

        return Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: const Text('Medicine Library',
                style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: -0.5)),
            backgroundColor: Colors.transparent,
            elevation: 0,
            actions: [
              IconButton(
                tooltip: 'Chat',
                icon: const Icon(Icons.chat_bubble_outline_rounded),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatScreen(
                        patientId: patientId,
                        title: 'Chat',
                      ),
                    ),
                  );
                },
              ),
              StreamBuilder<List<PatientLogModel>>(
                stream: logService.getLogsStream(patientId),
                builder: (context, logSnap) {
                  final logs = logSnap.data ?? [];
                  final hasLogs = logs.isNotEmpty;

                  return Tooltip(
                    message: "Activity Log",
                    child: IconButton(
                      icon: Stack(
                        children: [
                          const Icon(Icons.history_edu_rounded),
                          if (hasLogs)
                            Positioned(
                              right: 0,
                              top: 0,
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: AppColors.danger,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                        ],
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PatientLogsScreen(patientId: patientId),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: Stack(
            children: [
              StreamBuilder<List<MedicineModel>>(
                stream: medService.getMedicinesStream(patientId),
                builder: (context, medSnap) {
                  if (medSnap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (medSnap.hasError) {
                    return Center(child: Text('Error: ${medSnap.error}'));
                  }
                  final meds = medSnap.data ?? [];

                  // Local reminders for the caretaker device for this patient scope.
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    NotificationService().syncMedicineReminders(
                      scopeKey: 'caretaker:$caretakerId|patient:$patientId',
                      medicines: meds,
                      titlePrefix: 'Patient medicine',
                    );
                  });

                  return StreamBuilder<List<AdherenceLogModel>>(
                    stream: adhService.getRecentLogs(patientId),
                    builder: (context, logSnap) {
                      final logs = logSnap.data ?? [];
                      final today = DateTime.now();

                      // Calculate Adherence Rate (mock calculation for demo)
                      double adherenceRate = 0.94; // as per mockup

                      if (meds.isEmpty) {
                        return ListView(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                          children: [
                            _AdherenceHeader(rate: adherenceRate),
                            const SizedBox(height: 40),
                            const _EmptyMedState(),
                          ],
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                        itemCount: meds.length + 1, // +1 for the header
                        itemBuilder: (_, i) {
                          if (i == 0) return _AdherenceHeader(rate: adherenceRate);

                          final med = meds[i - 1];
                          final todayLogs = logs.where((l) {
                            final ts = l.timestamp;
                            return l.medicineId == med.id &&
                                ts.year == today.year &&
                                ts.month == today.month &&
                                ts.day == today.day;
                          }).toList();

                          return _MedicineCard(
                            med: med,
                            todayLogs: todayLogs,
                            patientId: patientId,
                            caretakerModel: caretakerModel,
                            adhService: adhService,
                          );
                        },
                      );
                    },
                  );
                },
              ),
              // Bottom Add Button
              if (caretakerModel.role == UserRole.caretaker)
                Positioned(
                  left: 20,
                  right: 20,
                  bottom: 30,
                  child: GradientButton(
                    text: 'Add Medicine',
                    icon: Icons.add_rounded,
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AddMedicineScreen(patientId: patientId),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

// ─── Adherence Header Widget ─────────────────────────────────────────────────

class _AdherenceHeader extends StatelessWidget {
  final double rate;
  const _AdherenceHeader({required this.rate});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24, top: 10),
      child: GlassCard(
        padding: const EdgeInsets.all(24),
        borderRadius: 24,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Adherence Rate',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${(rate * 100).toInt()}%',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 70,
                  height: 70,
                  child: CircularProgressIndicator(
                    value: rate,
                    strokeWidth: 10,
                    backgroundColor: AppColors.primary.withOpacity(0.1),
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(AppColors.primary),
                    strokeCap: StrokeCap.round,
                  ),
                ),
                const Icon(Icons.trending_up_rounded,
                    color: AppColors.primary, size: 24),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Empty State Widget ──────────────────────────────────────────────────────

class _EmptyMedState extends StatelessWidget {
  const _EmptyMedState();

  @override
  Widget build(BuildContext context) {
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
  final String patientId;
  final UserModel caretakerModel;
  final AdherenceService adhService;

const _MedicineCard({
  required this.med,
  required this.todayLogs,
  required this.patientId,
  required this.caretakerModel,
  required this.adhService,
});
  @override
  Widget build(BuildContext context) {
    final isTaken = todayLogs.any((l) => l.taken);
    final isMissed = !isTaken && todayLogs.any((l) => !l.taken);
    final canManage = caretakerModel.role == UserRole.caretaker;

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
              child:
                  Icon(Icons.medication_rounded, color: statusColor, size: 24),
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
            if (canManage && !isTaken) ...[
              IconButton(
                icon: const Icon(Icons.check_circle_outline,
                    color: Colors.teal, size: 28),
                tooltip: 'Mark as Taken',
                onPressed: () async {
                  try {
                    await adhService.markTakenWithCamera(
                      patientId: patientId,
                      medicineId: med.id,
                      medicineName: med.name,
                      caretakerId: caretakerModel.uid,
                      caretakerName: caretakerModel.name,
                      scheduledTime: med.timings.first,
                    );
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).clearSnackBars();
                      ScaffoldMessenger.of(context)
                          .showSnackBar(SnackBar(content: Text('Error: $e')));
                    }
                  }
                },
              ),
            ] else ...[
              StatusPill(
                label: statusText,
                icon: statusIcon,
                baseColor: statusColor,
              ),
            ],
            // Edit / Delete menu
            if (canManage)
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert_rounded,
                    color: AppColors.textSecondary.withOpacity(0.6), size: 20),
                color: AppColors.surface,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                onSelected: (value) async {
                  if (value == 'edit') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            AddMedicineScreen(patientId: patientId, medicine: med),
                      ),
                    );
                  } else if (value == 'delete') {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (_) => AlertDialog(
                        backgroundColor: AppColors.surface,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        title: const Text('Delete Medicine',
                            style: TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w800)),
                        content: Text(
                            'Remove "${med.name}" from this patient\'s schedule?',
                            style:
                                const TextStyle(color: AppColors.textSecondary)),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancel',
                                style:
                                    TextStyle(color: AppColors.textSecondary)),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.danger),
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Delete',
                                style: TextStyle(color: Colors.white)),
                          ),
                        ],
                      ),
                    );
                    if (confirmed == true && context.mounted) {
                      try {
                        await MedicineService().deleteMedicine(med.id);
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).clearSnackBars();
                          ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error: $e')));
                        }
                      }
                    }
                  }
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(children: [
                      Icon(Icons.edit_outlined,
                          size: 16, color: AppColors.textPrimary),
                      SizedBox(width: 8),
                      Text('Edit',
                          style: TextStyle(color: AppColors.textPrimary)),
                    ]),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(children: [
                      Icon(Icons.delete_outline, size: 16, color: AppColors.danger),
                      SizedBox(width: 8),
                      Text('Delete', style: TextStyle(color: AppColors.danger)),
                    ]),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
