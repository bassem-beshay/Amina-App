import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Design tokens extracted from the Amina Figma onboarding flow.
/// Everything here mirrors the Figma spec (colors, spacing, radii, type).
class OnboardingTheme {
  OnboardingTheme._();

  // ---- Colors ----
  static const Color background = Color(0xFFF7F7F7);
  static const Color primary = Color(0xFF8B5CF6);
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textBlack = Color(0xFF000000);
  static const Color muted = Color(0xFF747474);
  static const Color placeholder = Color(0xFF808080);
  static const Color border = Color(0xFFE0E0E0);
  static const Color stepperTrack = Color(0xFFE5E5E5);

  /// Light purple used behind selected cards.
  static const Color selectedCardBg = Color(0xFFF5F3FF);

  /// Light purple used behind card icons.
  static const Color iconWrapBg = Color(0xFFEDE9FE);

  // ---- Spacing ----
  static const double sidePadding = 16.0;
  static const double contentWidth = 343.0;
  static const double gap8 = 8.0;
  static const double gap12 = 12.0;
  static const double gap16 = 16.0;
  static const double gap24 = 24.0;
  static const double gap32 = 32.0;

  // ---- Radii ----
  static const double radiusField = 8.0;
  static const double radiusCard = 12.0;

  // ---- Control sizing ----
  static const double controlHeight = 48.0;

  // ---- Shadows ----
  static const List<BoxShadow> buttonShadow = [
    BoxShadow(
      color: Color(0x40000000), // rgba(0,0,0,0.25)
      offset: Offset(0, 2),
      blurRadius: 2,
    ),
  ];

  // ---- Typography (Inter) ----
  static TextStyle inter({
    required double size,
    FontWeight weight = FontWeight.w400,
    Color color = textPrimary,
    double? height,
    double? letterSpacing,
  }) {
    return GoogleFonts.inter(
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );
  }

  // Common text styles
  static TextStyle get title => inter(size: 24, weight: FontWeight.w700, color: textPrimary);
  static TextStyle get subtitle => inter(size: 16, weight: FontWeight.w400, color: muted);
  static TextStyle get buttonLabel => inter(size: 18, weight: FontWeight.w500, color: Colors.white);
  static TextStyle get fieldText => inter(size: 14, weight: FontWeight.w400, color: textPrimary);
  static TextStyle get fieldHint => inter(size: 14, weight: FontWeight.w400, color: placeholder);
  static TextStyle get socialLabel => inter(size: 16, weight: FontWeight.w400, color: textPrimary);
}
