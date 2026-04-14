import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../models/patient_model.dart';
import '../../../services/patient_service.dart';
import '../../../widgets/glass_components.dart';
import '../../app_theme.dart';
import '../patient_detail_screen.dart';

class CaretakerPatientsTab extends StatefulWidget {
  final Function(String)? onPatientSelected;
  const CaretakerPatientsTab({super.key, this.onPatientSelected});

  @override
  State<CaretakerPatientsTab> createState() => CaretakerPatientsTabState();
}

class CaretakerPatientsTabState extends State<CaretakerPatientsTab> {
  final _patientService = PatientService();
  final _caretakerId = FirebaseAuth.instance.currentUser?.uid ?? '';

  // ─── Link Patient by Email Dialog ──────────────────────────────────────────

  void showLinkPatientDialog() {
    final emailCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isLoading = false;
    String? errorMsg;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.accent],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.link_rounded, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 12),
              const Text(
                'Link Patient',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Enter the email address of the patient\'s MediAssure account.',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary.withOpacity(0.8),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  autofocus: true,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Patient Email',
                    prefixIcon: const Icon(Icons.mail_outline_rounded,
                        color: AppColors.textSecondary, size: 20),
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
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    labelStyle:
                        const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                    errorStyle:
                        const TextStyle(fontSize: 11, color: AppColors.danger),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Email is required';
                    if (!v.contains('@')) return 'Enter a valid email';
                    return null;
                  },
                ),
                // Error message area
                if (errorMsg != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.danger.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline_rounded,
                            color: AppColors.danger, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            errorMsg!,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.danger,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(ctx),
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
                      setDlg(() {
                        isLoading = true;
                        errorMsg = null;
                      });

                      try {
                        await _patientService.linkPatientByEmail(
                          _caretakerId,
                          emailCtrl.text.trim(),
                        );
                        if (ctx.mounted) Navigator.pop(ctx);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Row(
                                children: [
                                  const Icon(Icons.check_circle_rounded,
                                      color: Colors.white, size: 18),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'Patient linked successfully!',
                                      style: const TextStyle(fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ],
                              ),
                              backgroundColor: Colors.teal.shade600,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              margin:
                                  const EdgeInsets.fromLTRB(20, 0, 20, 16),
                            ),
                          );
                        }
                      } on LinkError catch (e) {
                        // Known, user-facing errors
                        setDlg(() {
                          errorMsg = e.message;
                          isLoading = false;
                        });
                      } catch (e) {
                        setDlg(() {
                          errorMsg = 'Unexpected error. Please try again.';
                          isLoading = false;
                        });
                        debugPrint('❌ [LinkPatient] Unexpected error: $e');
                      }
                    },
              child: isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Text('Link Patient'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_caretakerId.isEmpty) {
      return const Center(child: Text('Not logged in'));
    }

    return StreamBuilder<List<LinkedPatient>>(
      stream: _patientService.getLinkedPatientsStream(_caretakerId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return _buildError(snapshot.error.toString());
        }

        final patients = snapshot.data ?? [];

        if (patients.isEmpty) return _buildEmptyState();

        return Column(
          children: [
            // Debug panel (only in debug mode)
            if (kDebugMode)
              _DebugPanel(caretakerId: _caretakerId, patients: patients),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
                itemCount: patients.length,
                itemBuilder: (_, i) => GestureDetector(
                  onTap: () {
                    if (widget.onPatientSelected != null) {
                      widget.onPatientSelected!(patients[i].uid);
                    }
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PatientDetailScreen(patient: patients[i]),
                      ),
                    );
                  },
                  child: _PatientCard(
                    patient: patients[i],
                    onUnlink: () => _confirmUnlink(patients[i]),
                    onViewMedicines: () {
                      if (widget.onPatientSelected != null) {
                        widget.onPatientSelected!(patients[i].uid);
                      }
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PatientDetailScreen(patient: patients[i]),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _confirmUnlink(LinkedPatient patient) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Unlink Patient?',
            style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
        content: Text(
          'Remove ${patient.name} from your patient list? Their data will be preserved.',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel',
                  style: TextStyle(color: AppColors.textSecondary))),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Unlink',
                  style: TextStyle(
                      color: AppColors.danger, fontWeight: FontWeight.w700))),
        ],
      ),
    );
    if (confirm == true && mounted) {
      await _patientService.unlinkPatient(_caretakerId, patient.uid);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${patient.name} unlinked'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.textPrimary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
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
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary.withOpacity(0.2),
                      AppColors.accent.withOpacity(0.1),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
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
                'Link a patient using their MediAssure account email.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary.withOpacity(0.8),
                ),
              ),
              const SizedBox(height: 24),
              GradientButton(
                text: 'Link First Patient',
                icon: Icons.person_add_rounded,
                onPressed: showLinkPatientDialog,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildError(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded,
                size: 48, color: AppColors.danger),
            const SizedBox(height: 12),
            Text(
              'Something went wrong',
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Debug Panel (debug mode only) ────────────────────────────────────────────

class _DebugPanel extends StatelessWidget {
  final String caretakerId;
  final List<LinkedPatient> patients;
  const _DebugPanel({required this.caretakerId, required this.patients});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.bug_report_rounded, color: Colors.amber, size: 14),
              SizedBox(width: 6),
              Text(
                'DEBUG PANEL',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: Colors.amber,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Caretaker UID: $caretakerId',
            style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
          ),
          Text(
            'Linked patients: ${patients.length}',
            style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
          ),
          ...patients.map((p) => Text(
                '  → ${p.name} (${p.uid}) — ${p.linkStatus}',
                style:
                    const TextStyle(fontSize: 10, color: AppColors.textSecondary),
              )),
        ],
      ),
    );
  }
}

// ─── Patient Card ─────────────────────────────────────────────────────────────

class _PatientCard extends StatelessWidget {
  final LinkedPatient patient;
  final VoidCallback onUnlink;
  final VoidCallback onViewMedicines;
  const _PatientCard({
    required this.patient,
    required this.onUnlink,
    required this.onViewMedicines,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            // Avatar with gradient
            Container(
              width: 52,
              height: 52,
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
                  patient.initials,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),

            // Patient info (from /users — no duplication)
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
                  if (patient.email.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      patient.email,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary.withOpacity(0.7),
                      ),
                    ),
                  ],
                  const SizedBox(height: 4),
                  // Link status badge
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: patient.linkStatus == 'active'
                          ? Colors.teal.withOpacity(0.12)
                          : Colors.orange.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      patient.linkStatus == 'active' ? '● Linked' : '◌ Pending',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: patient.linkStatus == 'active'
                            ? Colors.teal.shade700
                            : Colors.orange.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Actions: arrow + unlink menu
            PopupMenuButton<String>(
              onSelected: (v) {
                if (v == 'view') onViewMedicines();
                if (v == 'unlink') onUnlink();
              },
              icon: Icon(
                Icons.more_vert_rounded,
                color: AppColors.textSecondary.withOpacity(0.5),
              ),
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: 'view',
                  child: ListTile(
                    leading: Icon(Icons.medication_outlined, color: AppColors.primary),
                    title: Text('View Medicines'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const PopupMenuItem(
                  value: 'unlink',
                  child: ListTile(
                    leading: Icon(Icons.link_off_rounded, color: AppColors.danger),
                    title: Text('Unlink Patient',
                        style: TextStyle(color: AppColors.danger)),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
