import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../services/firestore_service.dart';
import '../../models/medicine_model.dart';
import '../../widgets/glass_components.dart';
import '../app_theme.dart';

class PatientMedicationsScreen extends StatefulWidget {
  const PatientMedicationsScreen({super.key});

  @override
  State<PatientMedicationsScreen> createState() =>
      _PatientMedicationsScreenState();
}

class _PatientMedicationsScreenState extends State<PatientMedicationsScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final String _currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
  final DateFormat _dateFormat = DateFormat('MMM d, yyyy');

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
        title: const Text('My Medications',
            style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: -0.5)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: StreamBuilder<List<MedicineModel>>(
        stream: _firestoreService.getMedications(_currentUserId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final meds = snapshot.data ?? [];

          if (meds.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
            itemCount: meds.length,
            itemBuilder: (context, index) {
              final med = meds[index];
              return _buildMedicineDetailCard(med);
            },
          );
        },
      ),
    );
  }

  Widget _buildMedicineDetailCard(MedicineModel med) {
    // Check if medication is currently active
    final now = DateTime.now();
    bool isActive =
        med.isActive && now.isAfter(med.startDate) && now.isBefore(med.endDate);

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
                  child: Text(
                    med.name,
                    style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.5),
                  ),
                ),
                StatusPill(
                  label: isActive ? 'Active' : 'Inactive',
                  icon: isActive ? Icons.bolt_rounded : Icons.pause_circle_rounded,
                  baseColor: isActive ? Colors.teal : Colors.grey,
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow(Icons.medication_rounded, "Dosage", med.dosage),
            const SizedBox(height: 10),
            _buildInfoRow(Icons.timer_rounded, "Schedule", med.timings.join(", ")),
            const SizedBox(height: 16),
            Container(
              height: 1,
              color: Colors.white.withOpacity(0.1),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildDateColumn(
                      "Started From", _dateFormat.format(med.startDate)),
                ),
                Container(width: 1, height: 30, color: Colors.white.withOpacity(0.1)),
                Expanded(
                  child: _buildDateColumn(
                      "Prescribed Till", _dateFormat.format(med.endDate),
                      isEnd: true),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.primary.withOpacity(0.8)),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                  fontSize: 12, 
                  fontWeight: FontWeight.w600, 
                  color: AppColors.textSecondary.withOpacity(0.8)),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDateColumn(String label, String date, {bool isEnd = false}) {
    return Column(
      crossAxisAlignment:
          isEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary.withOpacity(0.7))),
        const SizedBox(height: 4),
        Text(date,
            style: const TextStyle(
                fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
      ],
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
                child: const Icon(Icons.medication_liquid_rounded, size: 60, color: AppColors.primary),
              ),
              const SizedBox(height: 24),
              const Text(
                'Ready to Start?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'No medication records found yet. They will appear here once prescribed.',
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
