import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'app_theme.dart';
// LoginScreen import removed — navigation handled by AuthWrapper.
import '../widgets/dashboard/header.dart';
import '../widgets/dashboard/calendar.dart';
import '../widgets/dashboard/progress_card.dart';
import '../widgets/dashboard/action_grid.dart';
import '../widgets/dashboard/caretaker_list.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          _BackgroundBlobs(),
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // ── Header ───────────────────────────────────────────────
                  DashboardHeader(
                    email: user?.email ?? 'user@email.com',
                    onLogout: () => _handleLogout(context),
                  ),
                  const SizedBox(height: 28),

                  // ── This Week ────────────────────────────────────────────
                  _SectionLabel('This Week'),
                  const SizedBox(height: 12),
                  WeekCalendar(
                    onDaySelected: (_) {
                      // TODO: filter medicines by date
                    },
                  ),
                  const SizedBox(height: 28),

                  // ── Progress ─────────────────────────────────────────────
                  const ProgressCard(),
                  const SizedBox(height: 28),

                  // ── Quick Actions ─────────────────────────────────────────
                  _SectionLabel('Quick Actions'),
                  const SizedBox(height: 12),
                  ActionGrid(patientId: user?.uid ?? ''),
                  const SizedBox(height: 28),

                  // ── Caretakers ────────────────────────────────────────────
                  _SectionLabel('Caretakers'),
                  const SizedBox(height: 12),
                  const CaretakerList(),
                  const SizedBox(height: 36),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    // Navigation handled by AuthWrapper via authStateChanges.
    // Do NOT call Navigator.pushReplacement here.
  }
}

// ─── Section Label ─────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Text(text, style: AppTextStyles.headingMedium),
      );
}

// ─── Background Blobs ──────────────────────────────────────────────────────────

class _BackgroundBlobs extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: -60,
          right: -50,
          child: Container(
            width: 220,
            height: 220,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withOpacity(0.06),
            ),
          ),
        ),
        Positioned(
          top: 300,
          left: -70,
          child: Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.accent.withOpacity(0.05),
            ),
          ),
        ),
        Positioned(
          bottom: 200,
          right: -40,
          child: Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.warning.withOpacity(0.05),
            ),
          ),
        ),
      ],
    );
  }
}