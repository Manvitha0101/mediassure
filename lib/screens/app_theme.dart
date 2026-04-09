import 'package:flutter/material.dart';

// ─── Color Palette ─────────────────────────────────────────────────────────────
class AppColors {
  AppColors._();

  static const background   = Color(0xFFFCF9FE); // Very light pinkish-white
  static const surface      = Colors.white;
  static const primary      = Color(0xFF7A5BF3); // Indigo / Purple
  static const primaryLight = Color(0xFFF1EEFC);
  static const accent       = Color(0xFFFF5E89); // Pink
  static const accentLight  = Color(0xFFFFE8EE);
  static const warning      = Color(0xFFFF9F43);
  static const warningLight = Color(0xFFFFF3E4);
  static const danger       = Color(0xFFFF6B6B);
  static const dangerLight  = Color(0xFFFFEEEE);
  static const textPrimary  = Color(0xFF1E1E2D);
  static const textSecondary = Color(0xFF8A8A9E);
  static const cardShadow   = Color(0x0C000000);
  static const divider      = Color(0xFFF4F4F8);
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
            blurRadius: 10,
            offset: Offset(0, 3),
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
        fontFamily: 'Nunito',
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