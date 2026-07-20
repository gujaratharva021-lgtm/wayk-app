import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// OneX's visual identity: "sunrise on a health tracker."
/// Deep midnight-navy background, a warm sunrise-coral accent for
/// alarms/energy/streaks, and a mint-teal accent for health/vitality --
/// tying the palette directly to what this app is about: waking up
/// and building healthy streaks, one day at a time.
class AppColors {
  static const bg = Color(0xFF0F1115);
  static const surface = Color(0xFF1A1D24);
  static const surfaceHigh = Color(0xFF23272F);
  static const sunrise = Color(0xFFFF7A45); // primary: alarms, streaks, CTAs
  static const vitality = Color(0xFF34D9A6); // secondary: health, success
  static const textPrimary = Color(0xFFF5F3EF);
  static const textMuted = Color(0xFF8B8D97);
  static const danger = Color(0xFFFF5C6C);
  static const border = Color(0xFF2A2E37);
}

class AppTheme {
  static ThemeData get dark {
    final base = ThemeData.dark(useMaterial3: true);
    final bodyFont = GoogleFonts.manropeTextTheme(base.textTheme);
    final displayFont = GoogleFonts.spaceGroteskTextTheme(base.textTheme);

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.bg,
      colorScheme: base.colorScheme.copyWith(
        surface: AppColors.surface,
        primary: AppColors.sunrise,
        secondary: AppColors.vitality,
        error: AppColors.danger,
      ),
      textTheme: bodyFont
          .apply(bodyColor: AppColors.textPrimary, displayColor: AppColors.textPrimary)
          .copyWith(
            headlineLarge: displayFont.headlineLarge?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
            headlineMedium: displayFont.headlineMedium?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
            titleLarge: displayFont.titleLarge?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.bg,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.sunrise, width: 1.5),
        ),
        labelStyle: const TextStyle(color: AppColors.textMuted),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.sunrise,
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: AppColors.vitality),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.border),
        ),
      ),
      dividerTheme: const DividerThemeData(color: AppColors.border),
    );
  }
}
