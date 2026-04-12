import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
// Login navigation is handled by AuthWrapper — no import needed here.
import '../../widgets/glass_components.dart';
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
    final email = user?.email ?? 'Unknown Email';

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Profile',
            style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: -0.5)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: GlassCard(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
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
                        child: const Icon(Icons.person_rounded, size: 50, color: AppColors.primary),
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
                  email,
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
                const SizedBox(height: 48),
                Divider(color: Colors.white.withOpacity(0.1)),
                const SizedBox(height: 24),
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
      ),
    );
  }
}