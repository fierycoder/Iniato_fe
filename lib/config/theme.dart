import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Iniato design tokens — used across all screens for consistent styling.
class IniatoTheme {
  // ─── Brand Colors ───
  static const Color green        = Color(0xFF1B5E20);
  static const Color greenLight   = Color(0xFF2E7D32);
  static const Color greenMid     = Color(0xFF388E3C);
  static const Color greenDark    = Color(0xFF0D3B0F);
  static const Color greenSurface = Color(0xFFE8F5E9);
  static const Color yellow       = Color(0xFFFFD600);
  static const Color yellowDark   = Color(0xFFFBC02D);
  static const Color surface      = Color(0xFFF7F9F7);
  static const Color cardBg       = Color(0xFFFFFFFF);
  static const Color textPrimary  = Color(0xFF1A1A1A);
  static const Color textSecondary= Color(0xFF6B7280);
  static const Color textHint     = Color(0xFF9CA3AF);
  static const Color divider      = Color(0xFFE5E7EB);
  static const Color error        = Color(0xFFDC2626);
  static const Color success      = Color(0xFF16A34A);
  static const Color warning      = Color(0xFFF59E0B);

  // ─── Gradients ───
  static const LinearGradient brandGradient = LinearGradient(
    colors: [Color(0xFF1B5E20), Color(0xFF2E7D32), Color(0xFF43A047)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient heroGradient = LinearGradient(
    colors: [Color(0xFF0D3B0F), Color(0xFF1B5E20), Color(0xFF2E7D32)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  /// Alias kept for backward compatibility with existing screens.
  static const LinearGradient backgroundGradient = heroGradient;

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Colors.white, Color(0xFFF0FDF4)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient buttonGradient = LinearGradient(
    colors: [Color(0xFF2E7D32), Color(0xFF1B5E20)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ─── Dimensions ───
  static const double radiusXs = 6.0;
  static const double radiusSm = 10.0;
  static const double radiusMd = 16.0;
  static const double radiusLg = 24.0;
  static const double radiusXl = 32.0;
  static const double paddingSm = 8.0;
  static const double paddingMd = 16.0;
  static const double paddingLg = 24.0;

  // ─── Shadows ───
  static List<BoxShadow> cardShadow = [
    BoxShadow(
      color: const Color(0xFF1B5E20).withValues(alpha: 0.08),
      blurRadius: 24,
      spreadRadius: 0,
      offset: const Offset(0, 8),
    ),
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.04),
      blurRadius: 6,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> buttonShadow = [
    BoxShadow(
      color: const Color(0xFF1B5E20).withValues(alpha: 0.35),
      blurRadius: 16,
      offset: const Offset(0, 6),
    ),
  ];

  static List<BoxShadow> floatingShadow = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.14),
      blurRadius: 32,
      spreadRadius: 0,
      offset: const Offset(0, 12),
    ),
  ];

  // ─── Text Styles ───
  static const TextStyle display = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w800,
    color: green,
    letterSpacing: -0.5,
    height: 1.1,
  );

  static const TextStyle heading = TextStyle(
    fontSize: 26,
    fontWeight: FontWeight.w700,
    color: textPrimary,
    letterSpacing: -0.3,
  );

  static const TextStyle subheading = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: textPrimary,
    letterSpacing: -0.1,
  );

  static const TextStyle body = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: textPrimary,
    height: 1.5,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w500,
    color: textPrimary,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: textSecondary,
    letterSpacing: 0.2,
  );

  static const TextStyle label = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: textSecondary,
    letterSpacing: 0.4,
  );

  static const TextStyle buttonText = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: Colors.white,
    letterSpacing: 0.3,
  );

  static const TextStyle price = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w800,
    color: green,
    letterSpacing: -0.5,
  );

  // ─── Decorations ───
  static BoxDecoration cardDecoration = BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(radiusLg),
    boxShadow: cardShadow,
  );

  static BoxDecoration chipDecoration(Color color) => BoxDecoration(
    color: color.withValues(alpha: 0.1),
    borderRadius: BorderRadius.circular(radiusXl),
    border: Border.all(color: color.withValues(alpha: 0.2)),
  );

  static BoxDecoration glassDecoration = BoxDecoration(
    color: Colors.white.withValues(alpha: 0.85),
    borderRadius: BorderRadius.circular(radiusLg),
    border: Border.all(color: Colors.white.withValues(alpha: 0.6), width: 1),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.08),
        blurRadius: 20,
        offset: const Offset(0, 8),
      ),
    ],
  );

  // ─── Input Decoration ───
  static InputDecoration inputDecoration(String label, {IconData? icon, String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: const TextStyle(color: greenLight, fontSize: 14, fontWeight: FontWeight.w500),
      hintStyle: const TextStyle(color: textHint, fontSize: 14),
      prefixIcon: icon != null
          ? Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Icon(icon, color: greenLight, size: 20),
            )
          : null,
      filled: true,
      fillColor: const Color(0xFFF9FBF9),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMd),
        borderSide: const BorderSide(color: Color(0xFFDDE5DD), width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMd),
        borderSide: const BorderSide(color: greenLight, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMd),
        borderSide: const BorderSide(color: error, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMd),
        borderSide: const BorderSide(color: error, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  // ─── System UI ───
  static void setSystemUI({bool dark = false}) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: dark ? Brightness.light : Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ));
  }

  // ─── Material Theme ───
  static ThemeData get themeData => ThemeData(
    useMaterial3: true,
    primaryColor: green,
    colorScheme: ColorScheme.fromSeed(
      seedColor: green,
      primary: green,
      secondary: greenLight,
      surface: surface,
      error: error,
    ),
    scaffoldBackgroundColor: surface,
    fontFamily: 'Roboto',
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      titleTextStyle: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: Colors.white,
        letterSpacing: 0.3,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: green,
        foregroundColor: Colors.white,
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusMd)),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 28),
        textStyle: buttonText,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: green,
        side: const BorderSide(color: green, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusMd)),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusLg)),
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 6),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: greenSurface,
      labelStyle: const TextStyle(color: green, fontWeight: FontWeight.w600, fontSize: 12),
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: const Color(0xFF1A1A1A),
      contentTextStyle: const TextStyle(color: Colors.white, fontSize: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      behavior: SnackBarBehavior.floating,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: green,
      unselectedItemColor: Color(0xFF9CA3AF),
      type: BottomNavigationBarType.fixed,
      elevation: 0,
      selectedLabelStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
      unselectedLabelStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
    ),
    dividerTheme: const DividerThemeData(
      color: divider,
      thickness: 1,
      space: 1,
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: _FadeSlideTransitionBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      },
    ),
  );
}

/// Smooth fade+slide transition used across all named routes.
class _FadeSlideTransitionBuilder extends PageTransitionsBuilder {
  const _FadeSlideTransitionBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.04),
          end: Offset.zero,
        ).animate(curved),
        child: child,
      ),
    );
  }
}

/// Navigate with a smooth slide-up sheet-style transition.
Route<T> slideUpRoute<T>(Widget page) {
  return PageRouteBuilder<T>(
    pageBuilder: (_, __, ___) => page,
    transitionDuration: const Duration(milliseconds: 380),
    reverseTransitionDuration: const Duration(milliseconds: 280),
    transitionsBuilder: (_, animation, __, child) {
      final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutQuint);
      return SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero).animate(curved),
        child: child,
      );
    },
  );
}

/// Navigate with a fade+scale transition (for dialogs/modals).
Route<T> fadeScaleRoute<T>(Widget page) {
  return PageRouteBuilder<T>(
    pageBuilder: (_, __, ___) => page,
    transitionDuration: const Duration(milliseconds: 300),
    reverseTransitionDuration: const Duration(milliseconds: 200),
    transitionsBuilder: (_, animation, __, child) {
      final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutBack);
      return FadeTransition(
        opacity: animation,
        child: ScaleTransition(scale: Tween(begin: 0.92, end: 1.0).animate(curved), child: child),
      );
    },
  );
}

/// Navigate with a horizontal slide transition.
Route<T> slideRightRoute<T>(Widget page) {
  return PageRouteBuilder<T>(
    pageBuilder: (_, __, ___) => page,
    transitionDuration: const Duration(milliseconds: 320),
    reverseTransitionDuration: const Duration(milliseconds: 250),
    transitionsBuilder: (_, animation, __, child) {
      final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
      return SlideTransition(
        position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero).animate(curved),
        child: child,
      );
    },
  );
}
