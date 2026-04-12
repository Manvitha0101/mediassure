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

import 'screens/login_screen.dart';
import 'screens/patient/main_patient_screen.dart';

// ─── Future role-based imports (add when ready) ────────────────────────────────
// import 'screens/doctor/main_doctor_screen.dart';
// import 'screens/caretaker/main_caretaker_screen.dart';
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
          // ── Role-based routing (extend here in the future) ──────────────────
          // Example:
          //   final uid  = snapshot.data!.uid;
          //   final role = await Firestore...getRole(uid);   // fetch from users/
          //   if (role == 'doctor')     return const MainDoctorScreen();
          //   if (role == 'caretaker')  return const MainCaretakerScreen();
          //   return const MainPatientScreen();   // default / patient
          // ────────────────────────────────────────────────────────────────────
          return const MainPatientScreen();         // ← patient flow (current)
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
