import 'package:flutter/material.dart';

class AppColors {
  // Primary Brand Colors
  static const Color primary = Color(0xFF6B48FF); // Vibrant Purple
  static const Color primaryLight = Color(0xFF9075FF);
  static const Color primaryDark = Color(0xFF4A2BD4);

  static const Color secondary = Color(0xFF00E5FF); // Cyan/Teal accent
  static const Color secondaryDark = Color(0xFF00B3CC);

  // Backgrounds (Dark Mode Focus)
  static const Color backgroundDark = Color(0xFF0A0A0F);
  static const Color surfaceDark = Color(0xFF15151F);
  static const Color surfaceHighlightDark = Color(0xFF232336);

  // Backgrounds (Light Mode Focus)
  static const Color backgroundLight = Color(0xFFF5F5F7);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceHighlightLight = Color(0xFFEAEAEA);

  // Typography
  static const Color textPrimaryLight = Color(0xFF1A1A1A);
  static const Color textSecondaryLight = Color(0xFF666666);
  
  static const Color textPrimaryDark = Color(0xFFFFFFFF);
  static const Color textSecondaryDark = Color(0xFFA0A0A0);

  // Status Colors
  static const Color success = Color(0xFF00E676);
  static const Color error = Color(0xFFFF3D00);
  static const Color warning = Color(0xFFFFC400);
  static const Color info = Color(0xFF2979FF);

  // Player Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, secondary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
