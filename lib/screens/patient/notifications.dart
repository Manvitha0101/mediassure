import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../services/firestore_service.dart';
import '../../models/medicine_model.dart';
import '../../models/adherence_log_model.dart';
import '../../widgets/glass_components.dart';
import '../app_theme.dart';
import '../../debug/debug_logger.dart';

class PatientNotificationsScreen extends StatefulWidget {
  const PatientNotificationsScreen({super.key});

  @override
  State<PatientNotificationsScreen> createState() =>
      _PatientNotificationsScreenState();
}

class _PatientNotificationsScreenState
    extends State<PatientNotificationsScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final String _currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
  final DateFormat _dateFormat = DateFormat('MMM d, h:mm a');

  @override
  Widget build(BuildContext context) {
    if (_currentUserId.isEmpty) {
      return const Scaffold(
        body: Center(child: Text("User not logged in")),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Alerts',
            style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: -0.5)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: StreamBuilder<List<MedicineModel>>(
        stream: _firestoreService.getMedications(_currentUserId),
        builder: (context, medSnap) {
          if (medSnap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (medSnap.hasError) {
            DebugLogger.log(
              hypothesisId: 'FS',
              location: 'patient/notifications.dart',
              message: 'medications stream error',
              data: {'err': medSnap.error.toString()},
            );
            return Center(child: Text('Error: ${medSnap.error}'));
          }

          final meds = medSnap.data ?? const [];
          return StreamBuilder<List<AdherenceLogModel>>(
            stream: _firestoreService.getLogs(_currentUserId),
            builder: (context, logSnap) {
              if (logSnap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (logSnap.hasError) {
                DebugLogger.log(
                  hypothesisId: 'FS',
                  location: 'patient/notifications.dart',
                  message: 'adherenceLogs stream error',
                  data: {'err': logSnap.error.toString()},
                );
                return Center(child: Text('Error: ${logSnap.error}'));
              }

              final logs = logSnap.data ?? const [];
              final today = DateTime.now();

              final alerts = <_PatientAlert>[];
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
                      patientId: _currentUserId,
                      medicineId: med.id,
                      caretakerId: '',
                      caretakerName: '',
                      scheduledTime: timing,
                      timestamp: today,
                      taken: false,
                    ),
                  );

                  final isTaken = todayLog.id.isNotEmpty && todayLog.taken == true;
                  if (isTaken) continue; // Only show pending/missed

                  alerts.add(
                    _PatientAlert(
                      medicineName: med.name,
                      dosage: med.dosage,
                      timing: timing,
                      isMissed: todayLog.id.isNotEmpty && todayLog.taken == false,
                      createdAt: today,
                    ),
                  );
                }
              }

              if (alerts.isEmpty) return _buildEmptyState();

              // Missed first, then pending
              alerts.sort((a, b) {
                if (a.isMissed != b.isMissed) return a.isMissed ? -1 : 1;
                return a.medicineName.compareTo(b.medicineName);
              });

              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
                itemCount: alerts.length,
                itemBuilder: (context, index) {
                  return _buildAlertCard(alerts[index]);
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildAlertCard(_PatientAlert alert) {
    final icon = alert.isMissed ? Icons.cancel_rounded : Icons.schedule_rounded;
    final color = alert.isMissed ? Colors.redAccent : AppColors.warning;
    final label = alert.isMissed ? 'Missed' : 'Pending';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    alert.medicineName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700, 
                      fontSize: 15,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${alert.dosage} · ${alert.timing} · $label',
                    style: TextStyle(
                      color: AppColors.textSecondary.withOpacity(0.7), 
                      fontSize: 12,
                      fontWeight: FontWeight.w500
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _dateFormat.format(alert.createdAt),
                    style: TextStyle(
                      color: AppColors.textSecondary.withOpacity(0.55),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40.0),
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
                child: const Icon(Icons.notifications_off_rounded, size: 60, color: AppColors.primary),
              ),
              const SizedBox(height: 24),
              const Text(
                'Quiet for Now',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'No missed or pending medicines for today.',
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

class _PatientAlert {
  final String medicineName;
  final String dosage;
  final String timing;
  final bool isMissed;
  final DateTime createdAt;

  const _PatientAlert({
    required this.medicineName,
    required this.dosage,
    required this.timing,
    required this.isMissed,
    required this.createdAt,
  });
}
