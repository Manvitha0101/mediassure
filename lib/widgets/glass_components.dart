import 'dart:ui';
import 'package:flutter/material.dart';
import '../screens/app_theme.dart';

/// A premium full-screen background with a blurred image and soft gradient overlay.
class GlassBackground extends StatelessWidget {
  final Widget child;
  const GlassBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Clean beige gradient background
        Positioned.fill(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFF2E6DF), // Slightly lighter peach beige
                  AppColors.background, // Peach beige
                ],
              ),
            ),
          ),
        ),
        // A subtle decorative blob could go here, but keeping it neat
        Positioned(
          top: -100,
          right: -50,
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primaryLight.withOpacity(0.3),
            ),
          ),
        ),
        // The actual content
        SafeArea(child: child),
      ],
    );
  }
}

/// A frosted glass card with BackdropFilter and a subtle border.
class GlassCard extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsets padding;
  final double blur;
  final double opacity;

  const GlassCard({
    super.key,
    required this.child,
    this.borderRadius = 24.0,
    this.padding = const EdgeInsets.all(20.0),
    this.blur = 15.0,
    this.opacity = 0.15,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(opacity),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1.5,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

/// A soft purple-to-pink gradient button with rounded corners.
class GradientButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final IconData? icon;
  final List<Color>? gradientColors;

  const GradientButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.icon,
    this.gradientColors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors ?? [AppColors.primary, AppColors.accent],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: (gradientColors?.first ?? AppColors.primary).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 8),
            ],
            Text(
              text,
              style: const TextStyle(
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
}

/// Aesthetic status badges for medication adherence.
class StatusPill extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color baseColor;

  const StatusPill({
    super.key,
    required this.label,
    required this.icon,
    required this.baseColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: baseColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: baseColor.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: baseColor.withOpacity(0.8), size: 16),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: baseColor.withOpacity(0.9),
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
