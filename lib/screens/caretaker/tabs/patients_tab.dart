import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../models/patient_model.dart';
import '../../../services/patient_service.dart';
import '../../../widgets/glass_components.dart';
import '../../app_theme.dart';
import 'medicines_tab.dart'; // for navigating to a patient's medicines

class CaretakerPatientsTab extends StatefulWidget {
  final Function(String)? onPatientSelected;
  const CaretakerPatientsTab({super.key, this.onPatientSelected});

  @override
  State<CaretakerPatientsTab> createState() => _CaretakerPatientsTabState();
}

class _CaretakerPatientsTabState extends State<CaretakerPatientsTab> {
  final _patientService = PatientService();
  final _caretakerId = FirebaseAuth.instance.currentUser?.uid ?? '';

  // ─── Add Patient Dialog ────────────────────────────────────────────────────

  void _showAddPatientDialog() {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    String gender = 'Male';
    final ageCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isLoading = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text(
            'Add Patient',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              fontSize: 18,
            ),
          ),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _DialogField(
                    controller: nameCtrl,
                    label: 'Full Name',
                    icon: Icons.person_outline_rounded,
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Name is required' : null,
                  ),
                  const SizedBox(height: 14),
                  _DialogField(
                    controller: emailCtrl,
                    label: 'Email (optional)',
                    icon: Icons.mail_outline_rounded,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 14),
                  _DialogField(
                    controller: ageCtrl,
                    label: 'Age (optional)',
                    icon: Icons.cake_outlined,
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      if (v != null && v.isNotEmpty && int.tryParse(v) == null) {
                        return 'Enter a valid number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    value: gender,
                    decoration: InputDecoration(
                      labelText: 'Gender',
                      prefixIcon: const Icon(Icons.wc_rounded,
                          color: AppColors.textSecondary, size: 20),
                      filled: true,
                      fillColor: AppColors.background,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                            color: AppColors.divider, width: 1.5),
                      ),
                    ),
                    items: ['Male', 'Female', 'Other']
                        .map((g) =>
                            DropdownMenuItem(value: g, child: Text(g)))
                        .toList(),
                    onChanged: (v) => setDlg(() => gender = v ?? gender),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel',
                  style: TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: isLoading
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setDlg(() => isLoading = true);
                      try {
                        await _patientService.addPatient(PatientModel(
                          patientId: '',
                          name: nameCtrl.text.trim(),
                          email: emailCtrl.text.trim(),
                          caretakerId: _caretakerId,
                          gender: gender,
                          age: ageCtrl.text.isNotEmpty
                              ? int.tryParse(ageCtrl.text.trim())
                              : null,
                        ));
                        if (ctx.mounted) Navigator.pop(ctx);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  '${nameCtrl.text.trim()} added successfully'),
                              backgroundColor: Colors.green.shade600,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                          );
                        }
                      } catch (e) {
                        setDlg(() => isLoading = false);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error: $e'),
                              backgroundColor: Colors.red,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      }
                    },
              child: isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text(
          'My Patients',
          style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: -0.5),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GradientButton(
              text: 'Add',
              icon: Icons.person_add_rounded,
              onPressed: _showAddPatientDialog,
            ),
          ),
        ],
      ),
      body: _caretakerId.isEmpty
          ? const Center(child: Text('Not logged in'))
          : StreamBuilder<List<PatientModel>>(
              stream:
                  _patientService.getPatientsByCaretaker(_caretakerId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                      child: Text('Error: ${snapshot.error}',
                          style:
                              const TextStyle(color: AppColors.textSecondary)));
                }
                final patients = snapshot.data ?? [];
                if (patients.isEmpty) return _buildEmptyState();
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
                  itemCount: patients.length,
                  itemBuilder: (_, i) => GestureDetector(
                    onTap: () {
                      if (widget.onPatientSelected != null) {
                        widget.onPatientSelected!(patients[i].patientId);
                      }
                    },
                    child: _PatientCard(patient: patients[i]),
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
                child: const Icon(Icons.people_outline_rounded,
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
                'Tap "Add" to link your first patient.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary.withOpacity(0.8),
                ),
              ),
              const SizedBox(height: 24),
              GradientButton(
                text: 'Add Patient',
                icon: Icons.person_add_rounded,
                onPressed: _showAddPatientDialog,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Patient Card ─────────────────────────────────────────────────────────────

class _PatientCard extends StatelessWidget {
  final PatientModel patient;
  const _PatientCard({required this.patient});

  @override
  Widget build(BuildContext context) {
    final initials = patient.name.isNotEmpty
        ? patient.name.trim().split(' ').map((w) => w[0]).take(2).join().toUpperCase()
        : '?';
    final subtitle = [
      if (patient.gender != null) patient.gender!,
      if (patient.age != null) '${patient.age} yrs',
    ].join(' · ');

    return Container(
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
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.accent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Text(
                  initials,
                  style: const TextStyle(
                    color: Colors.white,
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
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary.withOpacity(0.8),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
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
    );
  }
}

// ─── Reusable Dialog Field ────────────────────────────────────────────────────

class _DialogField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  const _DialogField({
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(
          fontSize: 14,
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.textSecondary, size: 20),
        filled: true,
        fillColor: AppColors.background,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.divider, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.danger, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.danger, width: 1.8),
        ),
        errorStyle:
            const TextStyle(fontSize: 11, color: AppColors.danger),
        labelStyle:
            const TextStyle(color: AppColors.textSecondary, fontSize: 13),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}
