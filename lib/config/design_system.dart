import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DesignSystem {
  // Spacing Scale
  static const double space4 = 4.0;
  static const double space8 = 8.0;
  static const double space12 = 12.0;
  static const double space16 = 16.0;
  static const double space20 = 20.0;
  static const double space24 = 24.0;
  static const double space32 = 32.0;
  static const double space48 = 48.0;

  // Paddings
  static const EdgeInsets paddingAll4 = EdgeInsets.all(space4);
  static const EdgeInsets paddingAll8 = EdgeInsets.all(space8);
  static const EdgeInsets paddingAll12 = EdgeInsets.all(space12);
  static const EdgeInsets paddingAll16 = EdgeInsets.all(space16);
  static const EdgeInsets paddingAll20 = EdgeInsets.all(space20);
  static const EdgeInsets paddingAll24 = EdgeInsets.all(space24);

  static const EdgeInsets paddingHorizontal16 = EdgeInsets.symmetric(horizontal: space16);
  static const EdgeInsets paddingVertical16 = EdgeInsets.symmetric(vertical: space16);
  static const EdgeInsets paddingHorizontal24 = EdgeInsets.symmetric(horizontal: space24);
  static const EdgeInsets paddingVertical12 = EdgeInsets.symmetric(vertical: space12);

  // Widget Gaps
  static const SizedBox gapH4 = SizedBox(width: space4);
  static const SizedBox gapH8 = SizedBox(width: space8);
  static const SizedBox gapH12 = SizedBox(width: space12);
  static const SizedBox gapH16 = SizedBox(width: space16);
  static const SizedBox gapH24 = SizedBox(width: space24);

  static const SizedBox gapV4 = SizedBox(height: space4);
  static const SizedBox gapV8 = SizedBox(height: space8);
  static const SizedBox gapV12 = SizedBox(height: space12);
  static const SizedBox gapV16 = SizedBox(height: space16);
  static const SizedBox gapV20 = SizedBox(height: space20);
  static const SizedBox gapV24 = SizedBox(height: space24);
  static const SizedBox gapV32 = SizedBox(height: space32);

  // Radii
  static const double radius4 = 4.0;
  static const double radius8 = 8.0;
  static const double radius12 = 12.0;
  static const double radius16 = 16.0;
  static const double radius20 = 20.0;
  static const double radius24 = 24.0;
  static const double radius32 = 32.0;

  static BorderRadius borderRadius8 = BorderRadius.circular(radius8);
  static BorderRadius borderRadius12 = BorderRadius.circular(radius12);
  static BorderRadius borderRadius16 = BorderRadius.circular(radius16);
  static BorderRadius borderRadius20 = BorderRadius.circular(radius20);
  static BorderRadius borderRadius24 = BorderRadius.circular(radius24);
  static BorderRadius borderRadius32 = BorderRadius.circular(radius32);

  // Premium Shadows
  static List<BoxShadow> get premiumShadowLight => [
        BoxShadow(
          color: const Color(0xFF0F172A).withOpacity(0.04),
          offset: const Offset(0, 4),
          blurRadius: 20,
          spreadRadius: 0,
        ),
        BoxShadow(
          color: const Color(0xFF0F172A).withOpacity(0.02),
          offset: const Offset(0, 1),
          blurRadius: 3,
          spreadRadius: 0,
        ),
      ];

  static List<BoxShadow> get premiumShadowDark => [
        BoxShadow(
          color: Colors.black.withOpacity(0.2),
          offset: const Offset(0, 4),
          blurRadius: 16,
          spreadRadius: 0,
        ),
        BoxShadow(
          color: const Color(0xFF818CF8).withOpacity(0.03),
          offset: const Offset(0, 0),
          blurRadius: 1,
          spreadRadius: 1,
        ),
      ];

  static List<BoxShadow> getShadow(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? premiumShadowDark
        : premiumShadowLight;
  }

  // Premium Cards & Containers
  static BoxDecoration cardDecoration(BuildContext context, {double? radius, Color? customColor}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return BoxDecoration(
      color: customColor ?? (isDark ? const Color(0xFF1E293B) : Colors.white),
      borderRadius: BorderRadius.circular(radius ?? radius16),
      border: Border.all(
        color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        width: 1.0,
      ),
      boxShadow: getShadow(context),
    );
  }

  static BoxDecoration inputDecoration(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return BoxDecoration(
      color: isDark ? const Color(0xFF0B0F19) : Colors.white,
      borderRadius: BorderRadius.circular(radius12),
      border: Border.all(
        color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        width: 1.2,
      ),
    );
  }

  // Typography Cairo / Outfit
  static String get fontFamily => GoogleFonts.cairo().fontFamily ?? 'Cairo';

  // Responsive Layout Checkers
  static bool isSmallPhone(BuildContext context) => MediaQuery.of(context).size.width < 360;
  static bool isTablet(BuildContext context) => MediaQuery.of(context).size.width >= 768;
}
