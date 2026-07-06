import 'package:flutter/material.dart';
import '../../config/onboarding_theme.dart';

/// A selectable option card with a leading icon, title, subtitle and a
/// trailing radio (Figma "card-User" / "card-Provider" and the compact
/// "sub-Company" / "sub-Individual").
class SelectableCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  /// Compact variant used inside the provider sub-panel.
  final bool compact;

  const SelectableCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final double iconWrap = compact ? 36 : 48;
    final double iconSize = compact ? 20 : 24;
    final double titleSize = compact ? 15 : 16;
    final double subSize = compact ? 12 : 13;
    final EdgeInsets padding =
        compact ? const EdgeInsets.all(12) : const EdgeInsets.all(16);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(OnboardingTheme.radiusCard),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: padding,
          decoration: BoxDecoration(
            color: selected ? OnboardingTheme.selectedCardBg : Colors.white,
            borderRadius: BorderRadius.circular(OnboardingTheme.radiusCard),
            border: Border.all(
              color: selected ? OnboardingTheme.primary : OnboardingTheme.border,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: iconWrap,
                height: iconWrap,
                decoration: BoxDecoration(
                  color: OnboardingTheme.iconWrapBg,
                  borderRadius: BorderRadius.circular(compact ? 10 : 12),
                ),
                child: Icon(icon, size: iconSize, color: OnboardingTheme.primary),
              ),
              SizedBox(width: compact ? 10 : 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: OnboardingTheme.inter(
                        size: titleSize,
                        weight: FontWeight.w600,
                        color: OnboardingTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: OnboardingTheme.inter(
                        size: subSize,
                        color: OnboardingTheme.muted,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8),
              _Radio(selected: selected, size: compact ? 18 : 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _Radio extends StatelessWidget {
  final bool selected;
  final double size;

  const _Radio({required this.selected, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? OnboardingTheme.primary : OnboardingTheme.border,
          width: 2,
        ),
      ),
      child: selected
          ? Center(
              child: Container(
                width: size * 0.5,
                height: size * 0.5,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: OnboardingTheme.primary,
                ),
              ),
            )
          : null,
    );
  }
}
