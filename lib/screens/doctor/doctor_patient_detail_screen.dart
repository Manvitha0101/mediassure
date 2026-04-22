import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'dart:convert';

import '../../models/patient_model.dart';
import '../../models/adherence_log_model.dart';
import '../../models/medicine_model.dart';
import '../../models/prescription_model.dart';
import '../../services/adherence_service.dart';
import '../../services/medicine_service.dart';
import '../../services/prescription_service.dart';
import '../../utils/adherence_calculator.dart';
import '../../widgets/glass_components.dart';
import '../app_theme.dart';

class DoctorPatientDetailScreen extends StatefulWidget {
  final LinkedPatient patient;

  const DoctorPatientDetailScreen({super.key, required this.patient});

  @override
  State<DoctorPatientDetailScreen> createState() => _DoctorPatientDetailScreenState();
}

class _DoctorPatientDetailScreenState extends State<DoctorPatientDetailScreen> {
  final _adhService = AdherenceService();
  final _medService = MedicineService();
  final _prescriptionService = PrescriptionService();
  final _doctorId = FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text(widget.patient.name, style: const TextStyle(fontWeight: FontWeight.w800)),
          backgroundColor: AppColors.background,
          elevation: 0,
          bottom: const TabBar(
            isScrollable: true,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.primary,
            tabs: [
              Tab(text: 'Overview'),
              Tab(text: 'Timeline'),
              Tab(text: 'Medicines'),
              Tab(text: 'Prescriptions'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildOverviewTab(),
            _buildTimelineTab(),
            _buildMedicinesTab(),
            _buildPrescriptionsTab(),
          ],
        ),
      ),
    );
  }

  // ─── A. OVERVIEW (ADHERENCE SUMMARY) ───────────────────────────────────────

  Widget _buildOverviewTab() {
    return StreamBuilder<List<AdherenceLogModel>>(
      stream: _adhService.getLogsForPatient(widget.patient.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final logs = snapshot.data ?? [];
        final result = AdherenceCalculator.calculate(logs);

        Color statusColor = AppColors.danger;
        if (result.percentage >= 80) statusColor = Colors.green;
        else if (result.percentage >= 50) statusColor = Colors.orange;
        else if (result.total == 0) statusColor = AppColors.textSecondary;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Adherence Summary', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              const SizedBox(height: 16),
              GlassCard(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Text(
                      result.total == 0 ? 'No Data' : '${result.percentage.toStringAsFixed(1)}%',
                      style: TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: statusColor),
                    ),
                    const Text('Overall Adherence', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildStat('Total', result.total.toString(), AppColors.textPrimary),
                        _buildStat('Taken', result.taken.toString(), Colors.green),
                        _buildStat('Missed', result.missed.toString(), AppColors.danger),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
      ],
    );
  }

  // ─── B & C. RECENT ACTIVITY TIMELINE WITH PROOF VIEWER ─────────────────────

  Widget _buildTimelineTab() {
    return StreamBuilder<List<AdherenceLogModel>>(
      stream: _adhService.getRecentLogs(widget.patient.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final logs = snapshot.data ?? [];
        if (logs.isEmpty) {
          return const Center(child: Text('No recent activity.', style: TextStyle(color: AppColors.textSecondary)));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: logs.length,
          itemBuilder: (context, i) {
            final log = logs[i];
            final dateStr = DateFormat('MMM d, h:mm a').format(log.timestamp);
            
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              child: GlassCard(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      log.taken ? Icons.check_circle_rounded : Icons.cancel_rounded,
                      color: log.taken ? Colors.green : AppColors.danger,
                      size: 32,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(log.taken ? 'Taken' : 'Missed', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          Text('Scheduled: ${log.scheduledTime}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                          Text('Logged: $dateStr', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Removed _showPhotoProof since images are not stored in the cloud

  // ─── D. MEDICINES (READ-ONLY) ──────────────────────────────────────────────

  Widget _buildMedicinesTab() {
    return StreamBuilder<List<MedicineModel>>(
      stream: _medService.getMedicinesStream(widget.patient.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final meds = snapshot.data ?? [];
        if (meds.isEmpty) {
          return const Center(child: Text('No medicines found.', style: TextStyle(color: AppColors.textSecondary)));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: meds.length,
          itemBuilder: (context, i) {
            final med = meds[i];
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              child: GlassCard(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.medication_rounded, color: AppColors.primary, size: 32),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(med.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          Text(med.dosage, style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                          const SizedBox(height: 4),
                          Text('Timings: ${med.timings.join(", ")}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ─── E. PRESCRIPTIONS (READ-ONLY) ──────────────────────────────────────────

  Widget _buildPrescriptionsTab() {
    return StreamBuilder<List<Prescription>>(
      stream: _prescriptionService.getPrescriptionsForDoctorAndPatient(_doctorId, widget.patient.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final prescriptions = snapshot.data ?? [];
        if (prescriptions.isEmpty) {
          return const Center(child: Text('No prescriptions found.', style: TextStyle(color: AppColors.textSecondary)));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: prescriptions.length,
          itemBuilder: (context, i) {
            final p = prescriptions[i];
            final dateStr = DateFormat('MMM d, yyyy').format(DateTime.parse(p.uploadedAt));
            
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              child: GlassCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(dateStr, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Text('${p.medicines.length} Meds', style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    if (p.note != null && p.note!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(p.note!, style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                    ],
                    if (p.medicines.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: p.medicines.map((m) => Chip(label: Text(m, style: const TextStyle(fontSize: 12)))).toList(),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
