import 'package:flutter/material.dart';

// ─── Color Palette ─────────────────────────────────────────────────────────────
class AppColors {
  AppColors._();

  static const background   = Color(0xFFE8D4C8); // Warm peach beige
  static const surface      = Colors.white;
  static const primary      = Color(0xFF8B6BCC); // Middle violet
  static const primaryLight = Color(0xFFE0D8ED);
  static const accent       = Color(0xFFAFA0E0); // Lighter violet accent
  static const accentLight  = Color(0xFFF3F0FA);
  static const warning      = Color(0xFFFFB366);
  static const warningLight = Color(0xFFFFF6ED);
  static const danger       = Color(0xFFFF8585);
  static const dangerLight  = Color(0xFFFFF0F0);
  static const textPrimary  = Color(0xFF2C2C3D); // Slightly softer dark
  static const textSecondary = Color(0xFF9191A3);
  static const cardShadow   = Color(0x0A000000);
  static const divider      = Color(0xFFF1EFEA); // Warm divider
}

// ─── Text Styles ───────────────────────────────────────────────────────────────
class AppTextStyles {
  AppTextStyles._();

  static const headingLarge = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w800,
    color: AppColors.textPrimary,
    letterSpacing: -0.4,
  );

  static const headingMedium = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w800,
    color: AppColors.textPrimary,
    letterSpacing: -0.2,
  );

  static const headingSmall = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  static const bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
  );

  static const bodySmall = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );

  static const caption = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
  );
}

// ─── Shared Decorations ────────────────────────────────────────────────────────
class AppDecorations {
  AppDecorations._();

  static BoxDecoration card({
    double radius = 16,
    Color color = AppColors.surface,
  }) =>
      BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: const [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      );

  static BoxDecoration iconBadge({
    required Color color,
    double radius = 12,
  }) =>
      BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
      );
}

// ─── App Theme ─────────────────────────────────────────────────────────────────
class AppTheme {
  AppTheme._();

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          background: AppColors.background,
          surface: AppColors.surface,
        ),
        fontFamily: 'Poppins',
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.background,
          elevation: 0,
          titleTextStyle: AppTextStyles.headingMedium,
          iconTheme: IconThemeData(color: AppColors.textPrimary),
        ),
        cardTheme: CardThemeData(
          color: AppColors.surface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      );
}