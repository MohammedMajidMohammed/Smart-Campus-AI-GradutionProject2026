import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:easy_localization/easy_localization.dart';

class AppTheme {
  // --- Professional Typography ---
  static String getFontFamily(BuildContext context) {
    return context.locale.languageCode == 'ar' ? 'Cairo' : 'Inter';
  }

  static TextTheme getTextTheme(BuildContext context, Color textColor) {
    final bool isArabic = context.locale.languageCode == 'ar';
    final fontFunction = isArabic ? GoogleFonts.cairo : GoogleFonts.inter;
    
    return TextTheme(
      displayLarge: fontFunction(fontSize: 32, fontWeight: FontWeight.w800, color: textColor, letterSpacing: isArabic ? 0 : -1.0),
      displayMedium: fontFunction(fontSize: 28, fontWeight: FontWeight.w700, color: textColor, letterSpacing: isArabic ? 0 : -0.5),
      headlineLarge: fontFunction(fontSize: 24, fontWeight: FontWeight.w700, color: textColor, letterSpacing: isArabic ? 0 : -0.5),
      headlineMedium: fontFunction(fontSize: 20, fontWeight: FontWeight.w600, color: textColor),
      titleLarge: fontFunction(fontSize: 18, fontWeight: FontWeight.w600, color: textColor),
      bodyLarge: fontFunction(fontSize: 16, color: textColor, height: 1.5),
      bodyMedium: fontFunction(fontSize: 14, color: textColor.withValues(alpha: 0.7), height: 1.5),
    );
  }

  // Ultra-Professional Color Palette
  static const Color primaryColor = Color(0xFF1E8449); // Lighter Emerald Green
  static const Color primaryDark = Color(0xFF145A32); // Deep Forest Green
  static const Color primaryLight = Color(0xFF2ECC71); // Bright Accent Green
  
  static const Color secondaryColor = Color(0xFF145A32); // Secondary Deep Green
  static const Color accentColor = Color(0xFF145A32); // Accent Green
  
  // Backgrounds
  static const Color lightBackground = Color(0xFFFAF9F5); // Slate 50
  static const Color darkBackground = Color(0xFF0F0E0A); // Slate 900
  
  // Cards & Surfaces
  static const Color surfaceLight = Colors.white;
  static const Color surfaceDark = Color(0xFF1E1B15); // Slate 800
  
  // Text
  static const Color textPrimaryLight = Color(0xFF0F0E0A); // Slate 900
  static const Color textSecondaryLight = Color(0xFF64748B); // Slate 500
  static const Color textPrimaryDark = Color(0xFFF1F5F9); // Slate 100
  static const Color textSecondaryDark = Color(0xFF94A3B8); // Slate 400

  // Status
  static const Color success = Color(0xFF10B981); // Emerald 500
  static const Color warning = Color(0xFFF59E0B); // Amber 500
  static const Color error = Color(0xFFEF4444); // Red 500
  static const Color info = Color(0xFF1E8449); // Blue 500

  // Dynamic Theme Generator
  static ThemeData getTheme(BuildContext context, {required bool isDark}) {
    final Color primary = isDark ? primaryColor : primaryColor;
    final Color background = isDark ? darkBackground : lightBackground;
    final Color surface = isDark ? surfaceDark : surfaceLight;
    final Color textPrimary = isDark ? textPrimaryDark : textPrimaryLight;
    final Color textSecondary = isDark ? textSecondaryDark : textSecondaryLight;
    
    final bool isArabic = context.locale.languageCode == 'ar';
    final String family = isArabic ? 'Cairo' : 'Inter';
    final fontFunction = isArabic ? GoogleFonts.cairo : GoogleFonts.inter;

    return ThemeData(
      useMaterial3: true,
      brightness: isDark ? Brightness.dark : Brightness.light,
      primaryColor: primary,
      scaffoldBackgroundColor: background,
      fontFamily: family,
      colorScheme: isDark 
        ? ColorScheme.dark(
            primary: primary,
            secondary: secondaryColor,
            tertiary: accentColor,
            surface: surface,
            error: error,
            onPrimary: Colors.white,
            onSecondary: Colors.white,
            onSurface: textPrimary,
            onError: Colors.white,
          )
        : ColorScheme.light(
            primary: primary,
            secondary: secondaryColor,
            tertiary: accentColor,
            surface: surface,
            error: error,
            onPrimary: Colors.white,
            onSecondary: Colors.white,
            onSurface: textPrimary,
            onError: Colors.white,
          ),
      textTheme: getTextTheme(context, textPrimary),
      appBarTheme: AppBarTheme(
        elevation: 0,
        backgroundColor: Colors.transparent,
        centerTitle: true,
        iconTheme: IconThemeData(color: textPrimary),
        titleTextStyle: fontFunction(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: isArabic ? 0 : -0.5,
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05)),
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 2,
          shadowColor: primary.withValues(alpha: isDark ? 0.4 : 0.3),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: fontFunction(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: isArabic ? 0 : 0.5,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? const Color(0xFF1E1B15) : Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: error, width: 1),
        ),
        labelStyle: TextStyle(color: textSecondary),
        hintStyle: TextStyle(color: textSecondary.withValues(alpha: 0.7)),
      ),
      iconTheme: IconThemeData(color: textPrimary),
      dividerTheme: DividerThemeData(
        color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey.shade200,
        thickness: 1,
      ),
    );
  }

  // --- Static Defaults ---
  static ThemeData get lightTheme => throw UnimplementedError("Use getTheme(context)");
  static ThemeData get darkTheme => throw UnimplementedError("Use getTheme(context)");

  // --- Professional Decorations for Custom Widgets ---

  // Refined Glass/Soft Shadow style
  static List<BoxShadow> get professionalShadow => [
    BoxShadow(
      color: const Color(0xFF64748B).withValues(alpha: 0.1), // Blue-grey shadow
      blurRadius: 20,
      offset: const Offset(0, 10),
      spreadRadius: -5,
    ),
  ];

  static List<BoxShadow> get darkShadow => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.3),
      blurRadius: 20,
      offset: const Offset(0, 10),
      spreadRadius: -2,
    ),
  ];
}
