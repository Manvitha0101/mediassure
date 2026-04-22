import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../models/patient_model.dart';
import '../../services/patient_service.dart';
import '../../services/auth_service.dart';
import '../../services/adherence_service.dart';
import '../../utils/adherence_calculator.dart';
import '../../widgets/glass_components.dart';
import '../app_theme.dart';
import 'doctor_patient_detail_screen.dart';

class DoctorDashboardScreen extends StatefulWidget {
  const DoctorDashboardScreen({super.key});

  @override
  State<DoctorDashboardScreen> createState() => _DoctorDashboardScreenState();
}

class _DoctorDashboardScreenState extends State<DoctorDashboardScreen> {
  final _patientService = PatientService();
  final _authService = AuthService();
  final _adhService = AdherenceService();
  final _doctorId = FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'My Patients',
          style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: -0.5),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: AppColors.textSecondary),
            tooltip: 'Logout',
            onPressed: () => _authService.logOut(),
          ),
        ],
      ),
      body: _doctorId.isEmpty
          ? const Center(child: Text('Not logged in'))
          : StreamBuilder<List<PatientModel>>(
              stream: _patientService.getLinkedPatientsStreamForUser(_doctorId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: ${snapshot.error}',
                        style: const TextStyle(color: AppColors.textSecondary)),
                  );
                }
                final patients = snapshot.data ?? [];
                if (patients.isEmpty) return _buildEmptyState();

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
                  itemCount: patients.length,
                  itemBuilder: (_, i) => _PatientInsightCard(
                    patient: patients[i],
                    adhService: _adhService,
                  ),
                );
              },
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
                child: const Icon(Icons.medical_information_outlined,
                    size: 60, color: AppColors.primary),
              ),
              const SizedBox(height: 24),
              const Text(
                'No Patients Yet',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Wait for a caretaker to link a patient to your account.',
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

class _PatientInsightCard extends StatelessWidget {
  final PatientModel patient;
  final AdherenceService adhService;

  const _PatientInsightCard({
    required this.patient,
    required this.adhService,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: adhService.getLogsForPatient(patient.patientId),
      builder: (context, snapshot) {
        final logs = snapshot.data ?? [];
        final result = AdherenceCalculator.calculate(logs);

        // Determine color based on percentage
        Color statusColor = AppColors.danger;
        if (result.percentage >= 80) {
          statusColor = Colors.green;
        } else if (result.percentage >= 50) {
          statusColor = Colors.orange;
        } else if (result.total == 0) {
          statusColor = AppColors.textSecondary;
        }

        final initials = patient.name.isNotEmpty
            ? patient.name.trim().split(' ').map((w) => w[0]).take(2).join().toUpperCase()
            : '?';

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => DoctorPatientDetailScreen(patient: LinkedPatient.fromModel(patient)),
              ),
            );
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            child: GlassCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  // Avatar
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: statusColor.withOpacity(0.5), width: 2),
                    ),
                    child: Center(
                      child: Text(
                        initials,
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          patient.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          result.total == 0 ? 'No logs yet' : '${result.percentage.toStringAsFixed(1)}% Adherence',
                          style: TextStyle(
                            fontSize: 13,
                            color: result.total == 0 ? AppColors.textSecondary : statusColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (patient.email.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            patient.email,
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  // Arrow
                  Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.textSecondary.withOpacity(0.5),
                    size: 24,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
