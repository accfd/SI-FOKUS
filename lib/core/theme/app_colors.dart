import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ==========================================
  // LIGHT THEME (Teal/Green - Parent Reference)
  // ==========================================
  
  // Primary: Teal hijau tenang
  static const Color primaryLight = Color(0xFF2E7D6F);

  // Secondary: Teal gelap
  static const Color secondaryLight = Color(0xFF1B5E50);

  // Accent: Golden Amber
  static const Color accentLight = Color(0xFFFFB300);

  // Background: Off-white kehijauan
  static const Color backgroundLight = Color(0xFFF5FAF8);

  // Surfaces & Text (Light Mode)
  static const Color cardLight = Colors.white;
  static const Color textPrimaryLight = Color(0xFF1A3C34);
  static const Color textSecondaryLight = Color(0xFF5F7B74);
  static const Color borderLight = Color(0xFFE0EBE8);

  // ==========================================
  // DARK THEME (Sleek Dark Teal Mode)
  // ==========================================

  // Primary: Lighter Teal for Dark Mode
  static const Color primaryDark = Color(0xFF3B9E8D);

  // Secondary: Teal/Green Dark
  static const Color secondaryDark = Color(0xFF2E7D6F);

  // Accent: Golden Amber
  static const Color accentDark = Color(0xFFFFC107);

  // Background: Deep Dark Green-Blue
  static const Color backgroundDark = Color(0xFF0C1F1B);

  // Surfaces & Text (Dark Mode)
  static const Color cardDark = Color(0xFF142B26);
  static const Color textPrimaryDark = Color(0xFFE0ECE9);
  static const Color textSecondaryDark = Color(0xFF8BA6A0);
  static const Color borderDark = Color(0xFF1D3C35);

  // Common/Semantic Colors
  static const Color success = Color(0xFF10B981); // Emerald
  static const Color error = Color(0xFFEF4444); // Rose
  static const Color warning = Color(0xFFF59E0B); // Amber
  static const Color info = Color(0xFF3B82F6); // Blue
}
