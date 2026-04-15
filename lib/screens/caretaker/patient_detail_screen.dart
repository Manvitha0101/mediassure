import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../models/medicine_model.dart';
import '../../models/patient_model.dart';
import '../../services/medicine_service.dart';
import '../../widgets/glass_components.dart';
import '../app_theme.dart';
import '../add_medicine_screen.dart';
import '../../services/adherence_service.dart';
import '../../models/adherence_log_model.dart';

class PatientDetailScreen extends StatefulWidget {
  final LinkedPatient patient;
  const PatientDetailScreen({super.key, required this.patient});

  @override
  State<PatientDetailScreen> createState() => _PatientDetailScreenState();
}

class _PatientDetailScreenState extends State<PatientDetailScreen> {
  final CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  final _medService = MedicineService();
  final _adhService = AdherenceService();

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(widget.patient.name),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: GlassBackground(
        child: SafeArea(
          child: Column(
            children: [
              // Calendar Card
              _buildCalendarCard(),

              const SizedBox(height: 16),

              // Selected Day Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    Text(
                      _selectedDay == null
                          ? 'Select a day'
                          : DateFormat('EEEE, MMM d').format(_selectedDay!),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    const Icon(Icons.history_rounded,
                        size: 18, color: AppColors.textSecondary),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              Expanded(
                child: StreamBuilder<List<MedicineModel>>(
                  stream: _medService.getMedicinesStream(widget.patient.uid),
                  builder: (context, medSnapshot) {
                    if (medSnapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final meds = medSnapshot.data ?? [];
                    if (meds.isEmpty) return _buildEmptyState();

                    return StreamBuilder<List<AdherenceLogModel>>(
                      stream: _adhService.getLogsForDay(
                          widget.patient.uid, _selectedDay ?? DateTime.now()),
                      builder: (context, logSnapshot) {
                        final logs = logSnapshot.data ?? [];

                        return ListView.builder(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                          itemCount: meds.length,
                          itemBuilder: (_, i) {
                            // Find log for this medicine on this day
                            final medLogs = logs
                                .where((l) => l.medicineId == meds[i].id)
                                .toList();

                            return _CompactMedicineCard(
                              medicine: meds[i],
                              patientId: widget.patient.uid,
                              logs: medLogs,
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AddMedicineScreen(patientId: widget.patient.uid),
          ),
        ),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Medicine'),
      ),
    );
  }

  Widget _buildCalendarCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: GlassCard(
        padding: const EdgeInsets.symmetric(vertical: 8),
        borderRadius: 24,
        child: TableCalendar(
          firstDay: DateTime.utc(2024, 1, 1),
          lastDay: DateTime.utc(2030, 12, 31),
          focusedDay: _focusedDay,
          calendarFormat: _calendarFormat,
          selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
          onDaySelected: (selectedDay, focusedDay) {
            setState(() {
              _selectedDay = selectedDay;
              _focusedDay = focusedDay;
            });
          },
          calendarStyle: const CalendarStyle(
            todayDecoration: BoxDecoration(
              color: AppColors.accent,
              shape: BoxShape.circle,
            ),
            selectedDecoration: BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            defaultTextStyle: TextStyle(color: AppColors.textPrimary),
            weekendTextStyle: TextStyle(color: AppColors.textSecondary),
            outsideTextStyle: TextStyle(color: Colors.grey),
          ),
          headerStyle: HeaderStyle(
            formatButtonVisible: false,
            titleCentered: true,
            titleTextStyle: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 16,
              color: AppColors.textPrimary,
            ),
            leftChevronIcon: const Icon(Icons.chevron_left_rounded,
                color: AppColors.textPrimary),
            rightChevronIcon: const Icon(Icons.chevron_right_rounded,
                color: AppColors.textPrimary),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.medication_outlined,
              size: 48, color: AppColors.textSecondary),
          SizedBox(height: 12),
          Text(
            'No medicines scheduled',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _CompactMedicineCard extends StatelessWidget {
  final MedicineModel medicine;
  final String patientId;
  final List<AdherenceLogModel> logs;

  const _CompactMedicineCard({
    required this.medicine,
    required this.patientId,
    required this.logs,
  });

  void _showPhotoProof(BuildContext context, String imageBase64) {
    final imageBytes = base64Decode(imageBase64);
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.memory(
                imageBytes,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Verified Adherence Proof',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isTaken = logs.any((l) => l.taken);
    final proofBase64 = logs
        .firstWhere(
          (l) => l.imageBase64 != null && l.imageBase64!.isNotEmpty,
          orElse: () => AdherenceLogModel(
            id: '',
            patientId: patientId,
            medicineId: medicine.id,
            caretakerId: '',
            caretakerName: '',
            scheduledTime: '',
            timestamp: DateTime.now(),
            taken: false,
          ),
        )
        .imageBase64;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isTaken
                    ? Colors.teal.withOpacity(0.12)
                    : AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isTaken ? Icons.check_circle_rounded : Icons.medication_rounded,
                color: isTaken ? Colors.teal : AppColors.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    medicine.name,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      color: AppColors.textPrimary,
                      decoration: isTaken ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${medicine.dosage} • ${medicine.timings.join(", ")}',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
            if (proofBase64 != null)
              GestureDetector(
                onTap: () {
                  try {
                    _showPhotoProof(context, proofBase64);
                  } catch (_) {
                    // Invalid/missing base64 should never crash the UI.
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.camera_alt_rounded,
                    color: AppColors.accent,
                    size: 20,
                  ),
                ),
              )
            else
              const Icon(Icons.chevron_right_rounded,
                  color: AppColors.textSecondary, size: 20),
          ],
        ),
      ),
    );
  }
}
