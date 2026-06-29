import 'package:flutter/material.dart';

class AppColors {
  static const Color kPrimaryColor = Color(0xFF1E8449); // Lighter Emerald Green
  static const Color kSecondaryColor = Color(0xFF145A32); // Deep Forest Green
  
  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF2ECC71), Color(0xFF1E8449)], // Bright Green to Emerald Green
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient glassGradient = LinearGradient(
    colors: [
      Color(0x26FFFFFF), // White 15%
      Color(0x0DFFFFFF), // White 5%
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient surfaceGradient = LinearGradient(
    colors: [
      Color(0xFFFAF9F5), // Light background
      Color(0xFFE8F5E9), // Soft light green tint
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient studyGradient = LinearGradient(
    colors: [
      Color(0xFF1E8449), // Emerald Green
      Color(0xFF27AE60), // Nephrite Green
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient regulationsGradient = LinearGradient(
    colors: [
      Color(0xFF1E8449), // Emerald Green
      Color(0xFF2ECC71), // Vibrant Light Green
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const Color kBackgroundColorLight = Color(0xFFFAF9F5);
  static const Color kBackgroundColorDark = Color(0xFF0F0E0A);
}
