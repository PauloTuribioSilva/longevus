import 'package:flutter/material.dart';

class AppTheme {
  // Cores extraídas do styles.css
  static const Color bg = Color(0xFFF6F3F8);
  static const Color bgStrong = Color(0xFFEFEAF5);
  static const Color panel = Color(0xFFFFFFFF);
  static const Color primary = Color(0xFF471D61);
  static const Color primaryStrong = Color(0xFF2B123F);
  static const Color primarySoft = Color(0xFFF2EAF8);
  static const Color secondary = Color(0xFFF5CA5D);
  static const Color secondarySoft = Color(0xFFFFF7DC);
  static const Color textDark = Color(0xFF1B1821);
  static const Color textMuted = Color(0xFF6A5E74);
  static const Color line = Color(0xFFE8DFEF);
  static const Color success = Color(0xFF2E7D5C);
  static const Color successSoft = Color(0xFFEBF8F1);
  static const Color danger = Color(0xFFC94F61);
  static const Color dangerSoft = Color(0xFFFDECEF);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: bg,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        primary: primary,
        secondary: secondary,
        surface: panel,
        error: danger,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFD8CDE9)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        labelStyle: const TextStyle(color: textMuted, fontWeight: FontWeight.w600),
      ),
    );
  }
}