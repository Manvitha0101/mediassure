// ─── auth_wrapper.dart ─────────────────────────────────────────────────────────
// SINGLE SOURCE OF TRUTH for all post-authentication navigation.
//
// HOW IT WORKS:
//   - Streams FirebaseAuth.instance.authStateChanges()
//   - While waiting for Firebase: shows a cosmetic loading screen
//   - If the stream emits null (no user): shows LoginScreen
//   - If the stream emits a User: shows the correct dashboard
//
// RULES (do NOT break these):
//   - LoginScreen  → must NOT call Navigator.push/replace after login
//   - SignupScreen  → must NOT call Navigator.push/replace after signup
//   - Profile/Logout → must only call FirebaseAuth.instance.signOut()
//   - NO other screen should navigate to LoginScreen or a dashboard manually
// ─────────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:mediassure/screens/login_screen.dart';
import 'package:mediassure/screens/patient/main_patient_screen.dart';
import 'package:mediassure/screens/caretaker/caretaker_main_screen.dart';
import 'package:mediassure/screens/doctor_dashboard.dart';
import 'package:mediassure/screens/profile_completion_screen.dart';
import 'package:mediassure/models/user_role_model.dart';

// ─── Future role-based imports (add when ready) ────────────────────────────────
// import 'screens/doctor/main_doctor_screen.dart';
// ─────────────────────────────────────────────────────────────────────────────────

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {

        // ── Phase 1: Firebase is initialising ──────────────────────────────────
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _LoadingScreen();
        }

        // ── Phase 2: User is authenticated ─────────────────────────────────────
        if (snapshot.hasData && snapshot.data != null) {
          final uid = snapshot.data!.uid;
          
          return StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
            builder: (context, userSnap) {
              if (userSnap.connectionState == ConnectionState.waiting) {
                return const _LoadingScreen();
              }
              
              if (userSnap.hasData && userSnap.data != null && userSnap.data!.exists) {
                final userData = userSnap.data!.data() as Map<String, dynamic>;
                final userModel = UserModel.fromMap(userData, uid);
                
                if (!userModel.profileCompleted) {
                  return const ProfileCompletionScreen();
                }

                final role = userModel.role;
                if (role == UserRole.caretaker) return const CaretakerMainScreen();
                if (role == UserRole.patient) return const MainPatientScreen();
                if (role == UserRole.doctor) return const DoctorDashboard();
              }
              
              // default fallback for unknown role or error
              return const LoginScreen();
            },
          );
        }

        // ── Phase 3: No user — show login ──────────────────────────────────────
        return const LoginScreen();
      },
    );
  }
}

// ─── Loading Screen ─────────────────────────────────────────────────────────────
/// Shown only during the brief Firebase auth-state check on cold start (~<1 s).
/// Purely cosmetic. Has no navigation logic.
class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xfff8f9fc),
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
