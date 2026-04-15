import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../services/firestore_service.dart';
import '../../models/medicine_model.dart';
import '../../models/adherence_log_model.dart';
import '../../widgets/glass_components.dart';
import '../app_theme.dart';
import '../../debug/debug_logger.dart';

class PatientHistoryScreen extends StatefulWidget {
  const PatientHistoryScreen({super.key});

  @override
  State<PatientHistoryScreen> createState() => _PatientHistoryScreenState();
}

class _PatientHistoryScreenState extends State<PatientHistoryScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final String _currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
  final DateFormat _dateFormat = DateFormat('MMMM d, yyyy');
  final DateFormat _timeFormat = DateFormat('h:mm a');

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
        title: const Text('Adherence History',
            style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: -0.5)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: StreamBuilder<List<MedicineModel>>(
        stream: _firestoreService.getMedications(_currentUserId),
        builder: (context, medSnapshot) {
          if (medSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (medSnapshot.hasError) {
            DebugLogger.log(
              hypothesisId: 'FS',
              location: 'patient/history.dart',
              message: 'medications stream error',
              data: {'err': medSnapshot.error.toString()},
            );
            return Center(child: Text('Error: ${medSnapshot.error}'));
          }

          // Build mapping from medicineId -> medicineName
          final meds = medSnapshot.data ?? [];
          final Map<String, String> medicineNameMap = {};
          for (var med in meds) {
            medicineNameMap[med.id] = med.name;
          }

          return StreamBuilder<List<AdherenceLogModel>>(
            stream: _firestoreService.getLogs(_currentUserId),
            builder: (context, logSnapshot) {
              if (logSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (logSnapshot.hasError) {
                DebugLogger.log(
                  hypothesisId: 'FS',
                  location: 'patient/history.dart',
                  message: 'adherenceLogs stream error',
                  data: {'err': logSnapshot.error.toString()},
                );
                return Center(child: Text('Error: ${logSnapshot.error}'));
              }

              final logs = logSnapshot.data ?? [];

              if (logs.isEmpty) {
                return _buildEmptyState();
              }

              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
                itemCount: logs.length,
                itemBuilder: (context, index) {
                  final log = logs[index];
                  // Resolve the name (or fallback to Unknown Medicine if it was deleted)
                  final medName = medicineNameMap[log.medicineId] ?? 'Unknown Medicine';

                  return _buildLogCard(log, medName);
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildLogCard(AdherenceLogModel log, String medicineName) {
    Color statusColor = log.taken ? Colors.teal : Colors.redAccent;
    IconData statusIcon = log.taken ? Icons.check_circle_rounded : Icons.cancel_rounded;
    String statusText = log.taken ? 'Taken' : 'Missed';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(statusIcon, color: statusColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    medicineName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800, 
                      fontSize: 17,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.3
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Scheduled: ${log.scheduledTime}',
                    style: TextStyle(
                      color: AppColors.textSecondary.withOpacity(0.8),
                      fontSize: 12,
                      fontWeight: FontWeight.w600
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.event_note_rounded, size: 14, color: AppColors.textSecondary.withOpacity(0.6)),
                      const SizedBox(width: 4),
                      Text(
                        '${_dateFormat.format(log.timestamp)} • ${_timeFormat.format(log.timestamp)}',
                        style: TextStyle(
                          color: AppColors.textSecondary.withOpacity(0.6), 
                          fontSize: 12,
                          fontWeight: FontWeight.w500
                        ),
                      ),
                    ],
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
                child: const Icon(Icons.history_rounded, size: 60, color: AppColors.primary),
              ),
              const SizedBox(height: 24),
              const Text(
                'Empty History',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Your medication adherence logs will start appearing here once you mark them.',
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
