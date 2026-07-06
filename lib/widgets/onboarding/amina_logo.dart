import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../config/onboarding_theme.dart';

/// The Amina wordmark (أمينة / Amina), exported from Figma as a single-color
/// SVG and tinted at runtime so the same asset serves both the purple screens
/// and the white splash.
///
/// The logo's natural aspect ratio is 82.5 : 50 (Figma "Asset 3 1").
class AminaLogo extends StatelessWidget {
  final double width;
  final Color color;

  const AminaLogo({
    super.key,
    this.width = 80,
    this.color = OnboardingTheme.primary,
  });

  /// Purple logo used on the light onboarding screens (80×50 in Figma).
  const AminaLogo.purple({super.key, this.width = 80})
      : color = OnboardingTheme.primary;

  /// White logo used on the purple splash background.
  const AminaLogo.white({super.key, this.width = 150})
      : color = Colors.white;

  @override
  Widget build(BuildContext context) {
    // Aspect ratio from the Figma asset viewBox (82.5 × 49.5).
    final double height = width * (49.5 / 82.5);
    return SizedBox(
      width: width,
      height: height,
      child: SvgPicture.asset(
        'assets/images/amina_logo.svg',
        fit: BoxFit.contain,
        colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
      ),
    );
  }
}
