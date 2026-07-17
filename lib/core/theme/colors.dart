import 'package:flutter/material.dart';

class AppColors {
  // ========== PRIMARY COLORS ==========
  static const Color primary = Color(0xFF1DB954); // Spotify Green
  static const Color primaryLight = Color(0xFF1ED760);
  static const Color primaryDark = Color(0xFF169C46);

  // Vibrant accent colors
  static const Color neonPurple = Color(0xFF8B5CF6);
  static const Color neonBlue = Color(0xFF3B82F6);
  static const Color neonPink = Color(0xFFEC4899);
  static const Color neonOrange = Color(0xFFF97316);
  static const Color neonCyan = Color(0xFF06B6D4);

  // ========== SECONDARY COLORS ==========
  static const Color secondary = Color(0xFFFF6B9D);
  static const Color secondaryLight = Color(0xFFFF8FB3);
  static const Color secondaryDark = Color(0xFFE5527D);

  // ========== ACCENT COLORS ==========
  static const Color accent1 = Color(0xFF00D9FF); // Cyan
  static const Color accent2 = Color(0xFFFFD60A); // Gold
  static const Color accent3 = Color(0xFFFF006E); // Hot Pink
  static const Color accent4 = Color(0xFF8338EC); // Purple
  static const Color accent5 = Color(0xFF3A86FF); // Blue

  // ========== LIGHT THEME ==========
  static const Color backgroundLight = Color(0xFFF5F5F7);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color cardLight = Color(0xFFFAFAFC);
  static const Color textPrimaryLight = Color(0xFF1C1C1E);
  static const Color textSecondaryLight = Color(0xFF6E6E73);
  static const Color textHintLight = Color(0xFFAEAEB2);
  static const Color dividerLight = Color(0xFFE5E5EA);

  // ========== DARK THEME ==========
  static const Color backgroundDark = Color(0xFF000000); // Pure black for OLED
  static const Color surfaceDark = Color(0xFF121212);
  static const Color cardDark = Color(0xFF1E1E1E);
  static const Color elevatedDark = Color(0xFF282828);
  static const Color textPrimaryDark = Color(0xFFFFFFFF);
  static const Color textSecondaryDark = Color(0xFFB3B3B3);
  static const Color textHintDark = Color(0xFF6E6E73);
  static const Color dividerDark = Color(0xFF2C2C2E);

  // ========== GRADIENT COLLECTIONS ==========

  // Primary Gradients
  static const Gradient spotifyGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1DB954), Color(0xFF1ED760), Color(0xFF1AA34A)],
  );

  static const Gradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
  );

  static const Gradient sunsetGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFF6B6B), Color(0xFFFFE66D), Color(0xFFFF6B9D)],
  );

  static const Gradient oceanGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF2E3192), Color(0xFF1BFFFF)],
  );

  static const Gradient purpleHazeGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF8B5CF6), Color(0xFFEC4899), Color(0xFFF59E0B)],
  );

  // Card Gradients
  static const Gradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFFFFF), Color(0xFFFAFAFC)],
  );

  static const Gradient darkCardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1E1E1E), Color(0xFF121212)],
  );

  static const Gradient glassGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0x40FFFFFF),
      Color(0x20FFFFFF),
    ],
  );

  // ========== PREMIUM GRADIENTS ==========
  static const List<Gradient> popularGradients = [
    // Neon Dreams
    LinearGradient(
      colors: [Color(0xFF8B5CF6), Color(0xFFEC4899), Color(0xFFF59E0B)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    // Ocean Breeze
    LinearGradient(
      colors: [Color(0xFF06B6D4), Color(0xFF3B82F6), Color(0xFF8B5CF6)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    // Sunset Vibes
    LinearGradient(
      colors: [Color(0xFFF59E0B), Color(0xFFF97316), Color(0xFFEC4899)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    // Forest Mist
    LinearGradient(
      colors: [Color(0xFF10B981), Color(0xFF059669), Color(0xFF047857)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    // Royal Purple
    LinearGradient(
      colors: [Color(0xFF6366F1), Color(0xFF8B5CF6), Color(0xFFA855F7)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    // Cherry Blossom
    LinearGradient(
      colors: [Color(0xFFEC4899), Color(0xFFF472B6), Color(0xFFFBBF24)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    // Electric Blue
    LinearGradient(
      colors: [Color(0xFF0EA5E9), Color(0xFF06B6D4), Color(0xFF14B8A6)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    // Fire & Ice
    LinearGradient(
      colors: [Color(0xFFEF4444), Color(0xFFF97316), Color(0xFF06B6D4)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  ];

  // ========== GENRE GRADIENTS ==========
  static const Map<String, Gradient> genreGradients = {
    'Pop': LinearGradient(
      colors: [Color(0xFFEC4899), Color(0xFFF472B6)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    'Rock': LinearGradient(
      colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    'Hip-Hop': LinearGradient(
      colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    'Electronic': LinearGradient(
      colors: [Color(0xFF06B6D4), Color(0xFF0EA5E9)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    'Jazz': LinearGradient(
      colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    'Classical': LinearGradient(
      colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    'R&B': LinearGradient(
      colors: [Color(0xFFA855F7), Color(0xFF9333EA)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    'Country': LinearGradient(
      colors: [Color(0xFFF97316), Color(0xFFEA580C)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  };

  // ========== STATUS COLORS ==========
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // ========== GLASSMORPHISM ==========
  static Color glassLight = Colors.white.withValues(alpha: 0.15);
  static Color glassDark = Colors.white.withValues(alpha: 0.05);
  static Color glassBlur = Colors.white.withValues(alpha: 0.1);

  // ========== SHADOWS ==========
  static List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.08),
      blurRadius: 20,
      offset: const Offset(0, 10),
    ),
  ];

  static List<BoxShadow> elevatedShadow = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.15),
      blurRadius: 30,
      offset: const Offset(0, 15),
    ),
  ];

  static List<BoxShadow> neonShadow(Color color) => [
        BoxShadow(
          color: color.withValues(alpha: 0.5),
          blurRadius: 25,
          offset: const Offset(0, 10),
        ),
      ];
}
