import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
// Login navigation is handled by AuthWrapper — no import needed here.
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../widgets/glass_components.dart';
import '../../models/patient_model.dart';
import '../app_theme.dart';

class PatientProfileScreen extends StatelessWidget {
  const PatientProfileScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    // AuthWrapper listens to authStateChanges and will automatically
    // rebuild to show LoginScreen. No manual navigation needed.
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid;

    if (uid == null) {
      return const Scaffold(body: Center(child: Text('Not logged in')));
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Profile',
            style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: -0.5)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('patients').doc(uid).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Profile not found', style: TextStyle(color: Colors.white)));
          }

          final patient = PatientModel.fromDoc(snapshot.data!);

          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: GlassCard(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white.withOpacity(0.5), width: 2),
                          ),
                          child: CircleAvatar(
                            radius: 50,
                            backgroundColor: AppColors.primary.withOpacity(0.1),
                            child: Text(
                              patient.name.isNotEmpty ? patient.name[0].toUpperCase() : '?',
                              style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: AppColors.primary),
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
                          ),
                          child: const Icon(Icons.camera_alt_rounded, size: 16, color: AppColors.textPrimary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text(
                      patient.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    StatusPill(
                      label: 'Verified Patient',
                      icon: Icons.verified_user_rounded,
                      baseColor: AppColors.primary,
                    ),
                    const SizedBox(height: 32),

                    // Info Rows
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          _InfoRow(icon: Icons.email_outlined, label: 'Email', value: patient.email.isNotEmpty ? patient.email : 'N/A'),
                          const Divider(height: 24, color: Colors.white54),
                          _InfoRow(icon: Icons.cake_outlined, label: 'Age', value: '${patient.age} years'),
                          const Divider(height: 24, color: Colors.white54),
                          _InfoRow(icon: Icons.wc_outlined, label: 'Gender', value: patient.gender),
                          const Divider(height: 24, color: Colors.white54),
                          _InfoRow(icon: Icons.bloodtype_outlined, label: 'Blood Group', value: patient.bloodGroup ?? 'N/A'),
                          if (patient.medicalConditions.isNotEmpty) ...[
                            const Divider(height: 24, color: Colors.white54),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.medical_services_outlined, size: 20, color: AppColors.textSecondary),
                                const SizedBox(width: 12),
                                const SizedBox(
                                  width: 100,
                                  child: Text('Conditions', style: TextStyle(fontSize: 14, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                                ),
                                Expanded(
                                  child: Wrap(
                                    spacing: 6,
                                    runSpacing: 6,
                                    children: patient.medicalConditions.map((c) => Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: AppColors.accent.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(c, style: const TextStyle(fontSize: 12, color: AppColors.accent, fontWeight: FontWeight.w700)),
                                    )).toList(),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: GradientButton(
                        text: 'Logout My Account',
                        icon: Icons.logout_rounded,
                        onPressed: () => _logout(context),
                        gradientColors: [Colors.redAccent, Colors.orangeAccent.shade700],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  
  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.textSecondary),
        const SizedBox(width: 12),
        SizedBox(
          width: 100,
          child: Text(label, style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
        ),
        Expanded(
          child: Text(value, style: const TextStyle(fontSize: 15, color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }
}