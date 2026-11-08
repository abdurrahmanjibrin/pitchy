import 'package:flutter/material.dart';

class AppColors {
  // Duolingo Signature Colors
  static const Color green = Color(0xFF58CC02);
  static const Color greenDark = Color(0xFF46A302);
  static const Color greenLight = Color(0xFF89E219);
  static const Color greenSoft = Color(0xFFE5F9D3);

  static const Color blue = Color(0xFF1CB0F6);
  static const Color blueDark = Color(0xFF1899D6);
  static const Color blueSoft = Color(0xFFDDF4FF);

  static const Color yellow = Color(0xFFFFC800);
  static const Color yellowDark = Color(0xFFE5A500);
  static const Color yellowSoft = Color(0xFFFFF5D1);

  static const Color orange = Color(0xFFFF9600);
  static const Color orangeDark = Color(0xFFE58500);
  static const Color orangeSoft = Color(0xFFFFEAD0);

  static const Color red = Color(0xFFFF4B4B);
  static const Color redDark = Color(0xFFEA2B2B);
  static const Color redSoft = Color(0xFFFFDFDF);

  static const Color purple = Color(0xFFCE82FF);
  static const Color purpleDark = Color(0xFFA855F7);
  static const Color purpleSoft = Color(0xFFF3E8FF);

  // Backgrounds & Surfaces (Clean, bright, friendly)
  static const Color background = Color(0xFFF7F7F7);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceCard = Color(0xFFFFFFFF);
  static const Color surfaceElevated = Color(0xFFFFFFFF);
  static const Color surfaceBorder = Color(0xFFE5E5E5);
  static const Color border = Color(0xFFE5E5E5);
  static const Color cardBorder = Color(0xFFE5E5E5);
  static const Color borderBottom = Color(0xFFD6D6D6);

  // Brand Mapping
  static const Color primary = green;
  static const Color primaryLight = greenLight;
  static const Color primaryDark = greenDark;
  static const Color secondary = blue;
  static const Color secondaryLight = Color(0xFF70D3FF);
  static const Color accent = yellow;

  // Status Colors
  static const Color success = green;
  static const Color successBg = greenSoft;
  static const Color warning = orange;
  static const Color warningBg = orangeSoft;
  static const Color error = red;
  static const Color errorBg = redSoft;
  static const Color info = blue;
  static const Color infoBg = blueSoft;

  // Typography (Duolingo Crisp & High-Contrast)
  static const Color textPrimary = Color(0xFF3C3C3C);
  static const Color textSecondary = Color(0xFF777777);
  static const Color textMuted = Color(0xFFAFAFAF);
  static const Color divider = Color(0xFFE5E5E5);
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.background,
      fontFamily: null, // Clean system sans-serif
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColors.surface,
        error: AppColors.error,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: AppColors.textPrimary,
        onError: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: AppColors.textPrimary, size: 24),
        titleTextStyle: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.2,
        ),
        shape: Border(
          bottom: BorderSide(color: AppColors.surfaceBorder, width: 2),
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: AppColors.surfaceBorder, width: 2),
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.6,
          ),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          backgroundColor: Colors.white,
          minimumSize: const Size.fromHeight(52),
          side: const BorderSide(color: AppColors.surfaceBorder, width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.6,
          ),
          elevation: 0,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.blue,
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF7F7F7),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        hintStyle: const TextStyle(
          color: AppColors.textMuted,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        labelStyle: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.surfaceBorder, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.surfaceBorder, width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.blue, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.red, width: 2),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1.5,
      ),
    );
  }

  // Alias for backward compatibility
  static ThemeData get darkTheme => lightTheme;
}
