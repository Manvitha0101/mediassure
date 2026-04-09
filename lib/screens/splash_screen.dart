import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'app_theme.dart';
import 'login_screen.dart';
import 'dashboard_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double>   _logoFade;
  late final Animation<double>   _logoScale;
  late final Animation<double>   _titleFade;
  late final Animation<Offset>   _titleSlide;
  late final Animation<double>   _subtitleFade;
  late final Animation<double>   _pillFade;

  @override
  void initState() {
    super.initState();

    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    // Logo: fade + scale in 0–50 %
    _logoFade = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
    );
    _logoScale = Tween<double>(begin: 0.70, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.0, 0.55, curve: Curves.easeOutBack),
      ),
    );

    // Title: fade + slide up 30–70 %
    _titleFade = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.30, 0.70, curve: Curves.easeOut),
    );
    _titleSlide = Tween<Offset>(
      begin: const Offset(0, 0.25),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.30, 0.70, curve: Curves.easeOut),
    ));

    // Subtitle: 55–85 %
    _subtitleFade = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.55, 0.85, curve: Curves.easeOut),
    );

    // Pill badge: 70–100 %
    _pillFade = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.70, 1.0, curve: Curves.easeOut),
    );

    _ctrl.forward();

    // Navigate after animation settles
    Future.delayed(const Duration(milliseconds: 2800), _navigate);
  }

  Future<void> _navigate() async {
    if (!mounted) return;
    final user = FirebaseAuth.instance.currentUser;
    final destination = user != null
        ? const DashboardScreen()
        : const LoginScreen();

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 600),
        pageBuilder: (_, __, ___) => destination,
        transitionsBuilder: (_, animation, __, child) => FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
          child: child,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // ── Decorative blobs ─────────────────────────────────────────────
          _Blob(top: -80,  right: -60, size: 260, color: AppColors.primary.withOpacity(0.04)),
          _Blob(bottom: -100, left: -70, size: 300, color: AppColors.primary.withOpacity(0.03)),
          _Blob(top: 180, left: -50, size: 140, color: AppColors.accent.withOpacity(0.05)),
          _Blob(bottom: 160, right: -30, size: 120, color: AppColors.primary.withOpacity(0.05)),

          // ── Content ──────────────────────────────────────────────────────
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Logo badge
                FadeTransition(
                  opacity: _logoFade,
                  child: ScaleTransition(
                     scale: _logoScale,
                    child: const _LogoBadge(),
                  ),
                ),

                const SizedBox(height: 32),

                // App name
                FadeTransition(
                  opacity: _titleFade,
                  child: SlideTransition(
                    position: _titleSlide,
                    child: Text(
                      'MediAssure',
                      style: AppTextStyles.headingLarge.copyWith(
                        color: AppColors.textPrimary,
                        fontSize: 32,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                // Tagline
                FadeTransition(
                  opacity: _subtitleFade,
                  child: Text(
                    'Your Health, Our Priority',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.accent,
                      fontSize: 15,
                    ),
                  ),
                ),

                const SizedBox(height: 48),

                // Loading indicator ring
                FadeTransition(
                  opacity: _pillFade,
                  child: const CircularProgressIndicator(
                    color: AppColors.accent,
                    strokeWidth: 3,
                  ),
                ),
                const SizedBox(height: 12),
                FadeTransition(
                  opacity: _pillFade,
                  child: Text(
                    'Securing your health data...',
                    style: AppTextStyles.caption,
                  ),
                )
              ],
            ),
          ),

          // ── Bottom version tag ────────────────────────────────────────────
          Positioned(
            bottom: 36,
            left: 0,
            right: 0,
            child: FadeTransition(
              opacity: _pillFade,
              child: Text(
                'v1.0.0',
                textAlign: TextAlign.center,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary.withOpacity(0.5),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Logo Badge ────────────────────────────────────────────────────────────────

class _LogoBadge extends StatelessWidget {
  const _LogoBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.12),
            blurRadius: 30,
            offset: const Offset(0, 14),
          ),
          BoxShadow(
            color: AppColors.primary.withOpacity(0.15),
            blurRadius: 20,
            spreadRadius: 2,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: const Icon(
        Icons.favorite_rounded,
        color: AppColors.primary,
        size: 48,
      ),
    );
  }
}

// ─── Feature Pill ──────────────────────────────────────────────────────────────

class _FeaturePill extends StatelessWidget {
  const _FeaturePill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(40),
        border: Border.all(
          color: Colors.white.withOpacity(0.20),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _PillDot(color: AppColors.accent),
          const SizedBox(width: 8),
          Text(
            'Track · Remind · Care',
            style: AppTextStyles.caption.copyWith(
              color: Colors.white.withOpacity(0.80),
              letterSpacing: 0.5,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _PillDot extends StatelessWidget {
  const _PillDot({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        width: 7,
        height: 7,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          boxShadow: [
            BoxShadow(color: color.withOpacity(0.6), blurRadius: 6),
          ],
        ),
      );
}

// ─── Background Blob ───────────────────────────────────────────────────────────

class _Blob extends StatelessWidget {
  const _Blob({
    this.top,
    this.bottom,
    this.left,
    this.right,
    required this.size,
    required this.color,
  });

  final double? top;
  final double? bottom;
  final double? left;
  final double? right;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => Positioned(
        top: top,
        bottom: bottom,
        left: left,
        right: right,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
          ),
        ),
      );
}