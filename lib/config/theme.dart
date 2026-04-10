import 'package:flutter/material.dart';

/// Iniato design tokens — used across all screens for consistent styling.
class IniatoTheme {
  // ─── Brand Colors ───
  static const Color green = Color(0xFF1B5E20);
  static const Color greenLight = Color(0xFF388E3C);
  static const Color greenDark = Color(0xFF0D3B0F);
  static const Color yellow = Color(0xFFFFEB3B);
  static const Color yellowDark = Color(0xFFFBC02D);
  static const Color surface = Color(0xFFF5F5F5);
  static const Color cardBg = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color error = Color(0xFFD32F2F);
  static const Color success = Color(0xFF2E7D32);

  // ─── Gradients ───
  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [Color(0xE61B5E20), Color(0x991B5E20), Color(0x4DFFEB3B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient buttonGradient = LinearGradient(
    colors: [green, Color(0xB31B5E20)],
  );

  // ─── Dimensions ───
  static const double radiusSm = 8.0;
  static const double radiusMd = 16.0;
  static const double radiusLg = 24.0;
  static const double paddingSm = 8.0;
  static const double paddingMd = 16.0;
  static const double paddingLg = 24.0;

  // ─── Shadows ───
  static List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Colors.black.withOpacity(0.1),
      blurRadius: 20,
      spreadRadius: 2,
      offset: const Offset(0, 10),
    ),
  ];

  static List<BoxShadow> buttonShadow = [
    BoxShadow(
      color: Colors.black.withOpacity(0.15),
      blurRadius: 12,
      offset: const Offset(0, 6),
    ),
  ];

  // ─── Text Styles ───
  static const TextStyle heading = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: green,
    letterSpacing: 0.5,
  );

  static const TextStyle subheading = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: textPrimary,
  );

  static const TextStyle body = TextStyle(
    fontSize: 15,
    color: textPrimary,
    height: 1.4,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 13,
    color: textSecondary,
  );

  static const TextStyle buttonText = TextStyle(
    color: yellow,
    fontWeight: FontWeight.bold,
    fontSize: 17,
  );

  // ─── Card Decoration ───
  static BoxDecoration cardDecoration = BoxDecoration(
    color: Colors.white.withOpacity(0.92),
    borderRadius: BorderRadius.circular(radiusLg),
    boxShadow: cardShadow,
  );

  // ─── Input Decoration ───
  static InputDecoration inputDecoration(String label, {IconData? icon}) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: green),
      prefixIcon: icon != null ? Icon(icon, color: green) : null,
      filled: true,
      fillColor: Colors.white.withOpacity(0.9),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMd),
        borderSide: BorderSide(color: green.withOpacity(0.4), width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMd),
        borderSide: const BorderSide(color: green, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMd),
        borderSide: const BorderSide(color: error, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMd),
        borderSide: const BorderSide(color: error, width: 2),
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  // ─── Material Theme ───
  static ThemeData themeData = ThemeData(
    primaryColor: green,
    colorScheme: ColorScheme.fromSeed(
      seedColor: green,
      primary: green,
      secondary: yellow,
    ),
    scaffoldBackgroundColor: surface,
    appBarTheme: const AppBarTheme(
      backgroundColor: green,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: green,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
        ),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: greenDark,
      contentTextStyle: const TextStyle(color: Colors.white),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      behavior: SnackBarBehavior.floating,
    ),
  );
}
