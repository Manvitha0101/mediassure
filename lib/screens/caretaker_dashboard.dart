import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import '../services/patient_service.dart';
import '../services/medicine_service.dart';
import '../services/adherence_service.dart';
import '../models/patient_model.dart';
import '../models/medicine_model.dart';
import '../models/user_role_model.dart';
import '../models/adherence_log_model.dart';
import 'login_screen.dart';
import 'add_medicine_screen.dart';

class CaretakerDashboard extends StatefulWidget {
  const CaretakerDashboard({super.key});

  @override
  State<CaretakerDashboard> createState() => _CaretakerDashboardState();
}

class _CaretakerDashboardState extends State<CaretakerDashboard> {
  final _authService    = AuthService();
  final _patientService = PatientService();

  String? _uid;
  String? _userName;
  UserModel? _userModel;

  @override
  void initState() {
    super.initState();
    _uid = _authService.currentUserId;
    _loadUser();
  }

  Future<void> _loadUser() async {
    if (_uid == null) return;
    final user = await _authService.getUserRole(_uid!);
    if (mounted && user != null) {
      setState(() {
        _userModel = user;
        _userName  = user.name;
      });
    }
  }

  Future<void> _logout() async {
    await _authService.logOut();
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  // ─── Add Patient Dialog ───────────────────────────────────────────────────

  void _showAddPatientDialog() {
    final nameCtrl = TextEditingController();
    final ageCtrl  = TextEditingController();
    String gender  = 'Male';
    final formKey  = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Add Patient',
              style: TextStyle(fontWeight: FontWeight.bold)),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Name is required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: ageCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Age',
                    prefixIcon: Icon(Icons.cake_outlined),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Age is required';
                    if (int.tryParse(v.trim()) == null) return 'Enter a number';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: gender,
                  decoration: const InputDecoration(labelText: 'Gender'),
                  items: ['Male', 'Female', 'Other']
                      .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                      .toList(),
                  onChanged: (v) => setDlg(() => gender = v ?? gender),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _kPrimary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                Navigator.pop(ctx);
                await _createPatient(
                  name:   nameCtrl.text.trim(),
                  age:    int.parse(ageCtrl.text.trim()),
                  gender: gender,
                );
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createPatient({
    required String name,
    required int age,
    required String gender,
  }) async {
    if (_uid == null) return;
    try {
      final patient = PatientModel(
        patientId: '',
        name:      name,
        age:       age,
        gender:    gender,
        caretakerIds: [_uid!],
      );

      // Create patient doc → get new doc ID
      final patientId = await _patientService.createPatient(patient);

      // Also link patient to this user's patientIds array
      await _patientService.linkPatientToUser(_uid!, patientId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Patient "$name" added!'),
            backgroundColor: Colors.green.shade600,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Caretaker Dashboard',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
            if (_userName != null)
              Text('Hi, $_userName',
                  style: const TextStyle(fontSize: 12, color: Colors.white70)),
          ],
        ),
        backgroundColor: _kPrimary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Logout',
            onPressed: _logout,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: _kPrimary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add_rounded),
        label: const Text('Add Patient'),
        onPressed: _showAddPatientDialog,
      ),
      body: _uid == null
          ? const Center(child: CircularProgressIndicator())
          : _buildPatientList(),
    );
  }

  Widget _buildPatientList() {
    return StreamBuilder<List<PatientModel>>(
      stream: _patientService.getAssignedPatients(_uid!, 'caretaker'),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final patients = snapshot.data ?? [];
        if (patients.isEmpty) {
          return _emptyState();
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
          itemCount: patients.length,
          itemBuilder: (_, i) => _PatientCard(
            patient:   patients[i],
            caretakerId: _uid!,
          ),
        );
      },
    );
  }

  Widget _emptyState() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline_rounded,
                size: 80, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text('No patients yet',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade500)),
            const SizedBox(height: 8),
            Text('Tap "Add Patient" to get started',
                style: TextStyle(color: Colors.grey.shade400)),
          ],
        ),
      );
}

// ─── Patient Card ─────────────────────────────────────────────────────────────

class _PatientCard extends StatelessWidget {
  final PatientModel patient;
  final String caretakerId;

  const _PatientCard({
    required this.patient,
    required this.caretakerId,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: CircleAvatar(
            backgroundColor: _kPrimary.withOpacity(0.12),
            radius: 24,
            child: Text(
              patient.name.isNotEmpty ? patient.name[0].toUpperCase() : '?',
              style: const TextStyle(
                  color: _kPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 18),
            ),
          ),
          title: Text(
            patient.name,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          subtitle: Text(
            '${patient.gender ?? 'Unknown'} · ${patient.age} yrs'
            '${patient.bloodGroup != null ? ' · ${patient.bloodGroup}' : ''}',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.add_circle_outline_rounded,
                    color: _kPrimary),
                tooltip: 'Add Medicine',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        AddMedicineScreen(patientId: patient.patientId),
                  ),
                ),
              ),
              const Icon(Icons.expand_more),
            ],
          ),
          children: [
            _MedicineAdherenceList(patientId: patient.patientId),
          ],
        ),
      ),
    );
  }
}

// ─── Medicine + Adherence List ────────────────────────────────────────────────

class _MedicineAdherenceList extends StatelessWidget {
  final String patientId;
  const _MedicineAdherenceList({required this.patientId});

  @override
  Widget build(BuildContext context) {
    final medService = MedicineService();
    final adhService = AdherenceService();

    return StreamBuilder<List<MedicineModel>>(
      stream: medService.getMedicinesStream(patientId),
      builder: (context, medSnap) {
        if (medSnap.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final meds = medSnap.data ?? [];
        if (meds.isEmpty) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(
              'No medicines added yet.',
              style: TextStyle(color: Colors.grey.shade500),
            ),
          );
        }

        return StreamBuilder<List<AdherenceLogModel>>(
          stream: adhService.getRecentLogs(patientId),
          builder: (context, logSnap) {
            final logs = logSnap.data ?? [];
            final today = DateTime.now();

            return Column(
              children: [
                const Divider(height: 1),
                ...meds.map((med) {
                  final todayLogs = logs.where((l) {
                    final ts = l.timestamp;
                    return l.medicineId == med.id &&
                        ts.year == today.year &&
                        ts.month == today.month &&
                        ts.day == today.day;
                  }).toList();

                  final isTaken = todayLogs.any((l) => l.taken);
                  final isMissed = !isTaken && todayLogs.any((l) => !l.taken);

                  Color statusColor;
                  IconData statusIcon;
                  String statusText;

                  if (isTaken) {
                    statusColor = Colors.green.shade600;
                    statusIcon  = Icons.check_circle_rounded;
                    statusText  = 'Taken';
                  } else if (isMissed) {
                    statusColor = Colors.red.shade400;
                    statusIcon  = Icons.cancel_rounded;
                    statusText  = 'Missed';
                  } else {
                    statusColor = Colors.orange.shade400;
                    statusIcon  = Icons.schedule_rounded;
                    statusText  = 'Pending';
                  }

                  return ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.medication_rounded,
                          color: statusColor, size: 20),
                    ),
                    title: Text(
                      med.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    subtitle: Text(
                      '${med.dosage} · ${med.timings.join(", ")}',
                      style: TextStyle(
                          color: Colors.grey.shade500, fontSize: 12),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, color: statusColor, size: 18),
                        const SizedBox(width: 4),
                        Text(
                          statusText,
                          style: TextStyle(
                              color: statusColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 12),
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 8),
              ],
            );
          },
        );
      },
    );
  }
}

const Color _kPrimary = Color(0xFF4A6CF7);
