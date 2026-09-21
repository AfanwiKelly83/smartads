import 'package:flutter/material.dart';

class AppTheme {
  // Deep dark/navy background
  static const Color bgDark = Color(0xFF040914);
  static const Color surfaceDark = Color(0xFF0A1128);
  static const Color cardDark = Color(0xFF111D42);
  static const Color inputBg = Color(0xFF0D1530);

  // Bright cyan/blue accent
  static const Color accentPrimary = Color(0xFF00E5FF); // Bright Cyan
  static const Color accentLight = Color(0xFF84FFFF);
  static const Color accentDark = Color(0xFF00B0FF);
  
  // Indigo/Purple Gradient accents
  static const Color secondaryAccent = Color(0xFF651FFF); // Deep Purple

  // Neutral & Text Colors
  static const Color textWhite = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF90A4AE); // Blue-greyish text
  static const Color textMuted = Color(0xFF546E7A);
  static const Color borderSubtle = Color(0x33FFFFFF);

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF00E5FF), Color(0xFF651FFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient subtleGradient = LinearGradient(
    colors: [Color(0x3300E5FF), Color(0x11651FFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkCardGradient = LinearGradient(
    colors: [Color(0xFF111D42), Color(0xFF0A1128)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bgDark,
      colorScheme: const ColorScheme.dark(
        surface: surfaceDark,
        primary: accentPrimary,
        onPrimary: Colors.black,
        secondary: secondaryAccent,
        onSecondary: Colors.white,
      ),
      fontFamily: 'Roboto',
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: inputBg,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        hintStyle: const TextStyle(color: textMuted, fontSize: 14),
        labelStyle: const TextStyle(color: textSecondary, fontSize: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.transparent),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: borderSubtle),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: accentPrimary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFFF1744), width: 1.2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFFF1744), width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentPrimary,
          foregroundColor: Colors.black,
          elevation: 4,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}

extension ColorWithValues on Color {
  Color withValues({double? alpha}) {
    if (alpha == null) return this;
    return withValues(alpha: alpha.clamp(0.0, 1.0));
  }
}

