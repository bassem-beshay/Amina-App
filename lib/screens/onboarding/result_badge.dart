import 'package:flutter/material.dart';
import '../../config/onboarding_theme.dart';

/// Circular success/status badge used on the result screens
/// (Figma "badge-outer" → "badge-inner"): a light purple halo, a solid
/// purple disc, and a white glyph.
class ResultBadge extends StatelessWidget {
  final IconData icon;

  const ResultBadge({super.key, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      height: 120,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: OnboardingTheme.iconWrapBg,
      ),
      alignment: Alignment.center,
      child: Container(
        width: 88,
        height: 88,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: OnboardingTheme.primary,
        ),
        alignment: Alignment.center,
        child: Icon(icon, size: 44, color: Colors.white),
      ),
    );
  }
}
