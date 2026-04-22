import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/firestore_service.dart';
import '../../models/medicine_model.dart';
import '../../models/adherence_log_model.dart';
import '../../widgets/glass_components.dart';
import '../app_theme.dart';
import '../chat_screen.dart';

class PatientDashboardScreen extends StatefulWidget {
  const PatientDashboardScreen({super.key});

  @override
  State<PatientDashboardScreen> createState() => _PatientDashboardScreenState();
}

class _PatientDashboardScreenState extends State<PatientDashboardScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final String _currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  bool _isDateInRange(DateTime date, DateTime start, DateTime end) {
    final dateOnly = DateTime(date.year, date.month, date.day);
    final startOnly = DateTime(start.year, start.month, start.day);
    final endOnly = DateTime(end.year, end.month, end.day);
    return dateOnly.isAfter(startOnly.subtract(const Duration(days: 1))) &&
        dateOnly.isBefore(endOnly.add(const Duration(days: 1)));
  }

  AdherenceLogModel? _getLogForTiming(
      List<AdherenceLogModel> logs, String medicineId, String timing) {
    try {
      return logs.firstWhere(
        (log) =>
            log.medicineId == medicineId &&
            log.scheduledTime == timing &&
            _isToday(log.timestamp),
      );
    } catch (e) {
      return null;
    }
  }

  // Patients cannot mark medicines as taken/missed.

  @override
  Widget build(BuildContext context) {
    if (_currentUserId.isEmpty) {
      return const Scaffold(body: Center(child: Text("User not logged in")));
    }

    return Scaffold(
      backgroundColor: Colors.transparent, // Background handled by GlassBackground in MainPatientScreen
      appBar: AppBar(
        title: const Text('Today\'s Care', 
          style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: -0.5)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Chat',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChatScreen(
                    patientId: _currentUserId,
                    title: 'Chat',
                  ),
                ),
              );
            },
            icon: const Icon(Icons.chat_bubble_outline_rounded, size: 20),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.calendar_today_rounded, size: 20),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: StreamBuilder<List<MedicineModel>>(
        stream: _firestoreService.getMedications(_currentUserId),
        builder: (context, medSnapshot) {
          if (medSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (medSnapshot.hasError) {
            return Center(child: Text('Error: ${medSnapshot.error}'));
          }

          final allMeds = medSnapshot.data ?? [];
          final todayMeds = allMeds.where((m) {
            return m.isActive && _isDateInRange(DateTime.now(), m.startDate, m.endDate);
          }).toList();

          if (todayMeds.isEmpty) {
            return _buildEmptyState();
          }

          return StreamBuilder<List<AdherenceLogModel>>(
            stream: _firestoreService.getLogs(_currentUserId),
            builder: (context, logSnapshot) {
              if (logSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final allLogs = logSnapshot.data ?? [];
              final todayLogs = allLogs.where((l) => _isToday(l.timestamp)).toList();

              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 100), // Extra bottom padding for floating nav
                itemCount: todayMeds.length,
                itemBuilder: (context, index) {
                  final med = todayMeds[index];
                  return _buildMedicineCard(med, todayLogs);
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildMedicineCard(MedicineModel med, List<AdherenceLogModel> todayLogs) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        med.name,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Frequency: ${med.frequency}',
                        style: TextStyle(
                          color: AppColors.textSecondary.withOpacity(0.8),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.3)),
                  ),
                  child: Text(
                    med.dosage,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                )
              ],
            ),
            const SizedBox(height: 20),
            Container(
              height: 1,
              color: Colors.white.withOpacity(0.1),
            ),
            const SizedBox(height: 16),
            ...med.timings.map((timing) {
              final log = _getLogForTiming(todayLogs, med.id, timing);
              return _buildTimingRow(timing, med.id, log);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildTimingRow(String timing, String medicineId, AdherenceLogModel? log) {
    bool isTaken = log != null && log.taken;
    bool isMissed = log != null && !log.taken;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.access_time_rounded, color: AppColors.primary, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              timing,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          StatusPill(
            label: log == null
                ? 'Pending'
                : (isTaken ? 'Taken' : 'Missed'),
            icon: log == null
                ? Icons.schedule_rounded
                : (isTaken ? Icons.check_circle_rounded : Icons.cancel_rounded),
            baseColor: log == null
                ? AppColors.warning
                : (isTaken ? Colors.green : Colors.redAccent),
          ),
        ],
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
                  color: Colors.green.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.spa_rounded, size: 60, color: Colors.green),
              ),
              const SizedBox(height: 24),
              const Text(
                'Healthy Habits Pays Off!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'No medicines scheduled for today. Keep up the good work!',
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

class _CompactActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _CompactActionButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }
}
