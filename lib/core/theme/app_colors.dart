import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ==========================================
  // LIGHT THEME (HSL & Color)
  // ==========================================
  
  // Primary: Deep Indigo
  static const HSLColor primaryLightHsl = HSLColor.fromAHSL(1.0, 240.0, 0.80, 0.50);
  static final Color primaryLight = primaryLightHsl.toColor();

  // Secondary: Vibrant Teal
  static const HSLColor secondaryLightHsl = HSLColor.fromAHSL(1.0, 170.0, 0.85, 0.40);
  static final Color secondaryLight = secondaryLightHsl.toColor();

  // Accent: Golden Amber
  static const HSLColor accentLightHsl = HSLColor.fromAHSL(1.0, 40.0, 0.95, 0.50);
  static final Color accentLight = accentLightHsl.toColor();

  // Background: Soft Ice Blue/Grey
  static const HSLColor backgroundLightHsl = HSLColor.fromAHSL(1.0, 220.0, 0.30, 0.97);
  static final Color backgroundLight = backgroundLightHsl.toColor();

  // Surfaces & Text (Light Mode)
  static const Color cardLight = Colors.white;
  static final Color textPrimaryLight = const HSLColor.fromAHSL(1.0, 222.0, 0.40, 0.15).toColor();
  static final Color textSecondaryLight = const HSLColor.fromAHSL(1.0, 222.0, 0.20, 0.45).toColor();
  static final Color borderLight = const HSLColor.fromAHSL(1.0, 220.0, 0.20, 0.90).toColor();

  // ==========================================
  // DARK THEME (HSL & Color)
  // ==========================================

  // Primary: Deep Indigo (Lighter/Brighter for Dark Mode)
  static const HSLColor primaryDarkHsl = HSLColor.fromAHSL(1.0, 240.0, 0.80, 0.65);
  static final Color primaryDark = primaryDarkHsl.toColor();

  // Secondary: Vibrant Teal
  static const HSLColor secondaryDarkHsl = HSLColor.fromAHSL(1.0, 170.0, 0.85, 0.60);
  static final Color secondaryDark = secondaryDarkHsl.toColor();

  // Accent: Golden Amber
  static const HSLColor accentDarkHsl = HSLColor.fromAHSL(1.0, 40.0, 0.95, 0.65);
  static final Color accentDark = accentDarkHsl.toColor();

  // Background: Deep Dark Blue/Grey
  static const HSLColor backgroundDarkHsl = HSLColor.fromAHSL(1.0, 222.0, 0.40, 0.08);
  static final Color backgroundDark = backgroundDarkHsl.toColor();

  // Surfaces & Text (Dark Mode)
  static final Color cardDark = const HSLColor.fromAHSL(1.0, 222.0, 0.35, 0.13).toColor();
  static final Color textPrimaryDark = const HSLColor.fromAHSL(1.0, 220.0, 0.15, 0.95).toColor();
  static final Color textSecondaryDark = const HSLColor.fromAHSL(1.0, 220.0, 0.15, 0.70).toColor();
  static final Color borderDark = const HSLColor.fromAHSL(1.0, 222.0, 0.30, 0.18).toColor();

  // Common/Semantic Colors
  static const Color success = Color(0xFF10B981); // Emerald
  static const Color error = Color(0xFFEF4444); // Rose
  static const Color warning = Color(0xFFF59E0B); // Amber
  static const Color info = Color(0xFF3B82F6); // Blue
}
