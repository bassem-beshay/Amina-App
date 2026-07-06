import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../config/onboarding_theme.dart';
import 'amina_logo.dart';

/// Full-width purple primary action button (Figma "main-button").
/// height 48, radius 8, soft drop shadow, 18px medium white label.
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;

  const PrimaryButton({super.key, required this.label, this.onPressed});

  @override
  Widget build(BuildContext context) {
    final bool enabled = onPressed != null;
    return Opacity(
      opacity: enabled ? 1 : 0.6,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(OnboardingTheme.radiusField),
          onTap: onPressed,
          child: Container(
            height: OnboardingTheme.controlHeight,
            width: double.infinity,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: OnboardingTheme.primary,
              borderRadius: BorderRadius.circular(OnboardingTheme.radiusField),
              boxShadow: OnboardingTheme.buttonShadow,
            ),
            child: Text(label, style: OnboardingTheme.buttonLabel),
          ),
        ),
      ),
    );
  }
}

/// White text field with a light border (Figma "Component 3/6").
/// height 48, radius 8, 14px text, #808080 placeholder.
class AppTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;

  const AppTextField({
    super.key,
    required this.controller,
    required this.hint,
    this.keyboardType,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: OnboardingTheme.controlHeight,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(OnboardingTheme.radiusField),
        border: Border.all(color: OnboardingTheme.border),
      ),
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        onChanged: onChanged,
        cursorColor: OnboardingTheme.primary,
        style: OnboardingTheme.fieldText,
        // Fully neutralize the app-wide InputDecorationTheme (filled + outline
        // borders) so only this widget's own Container border shows.
        decoration: InputDecoration(
          isCollapsed: true,
          filled: false,
          contentPadding: EdgeInsets.zero,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          errorBorder: InputBorder.none,
          disabledBorder: InputBorder.none,
          focusedErrorBorder: InputBorder.none,
          hintText: hint,
          hintStyle: OnboardingTheme.fieldHint,
        ),
      ),
    );
  }
}

/// White outlined social button with an SVG brand icon (Google / Apple).
class SocialButton extends StatelessWidget {
  final String assetIcon;
  final String label;
  final VoidCallback? onPressed;

  const SocialButton({
    super.key,
    required this.assetIcon,
    required this.label,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(OnboardingTheme.radiusField),
        onTap: onPressed,
        child: Container(
          height: OnboardingTheme.controlHeight,
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(OnboardingTheme.radiusField),
            border: Border.all(color: OnboardingTheme.border),
          ),
          child: Row(
            children: [
              SvgPicture.asset(assetIcon, width: 24, height: 24),
              Expanded(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: OnboardingTheme.socialLabel,
                ),
              ),
              const SizedBox(width: 24), // balance the leading icon so text stays centered
            ],
          ),
        ),
      ),
    );
  }
}

/// Horizontal divider with a centered "Or" label (Figma "Frame 460").
class OrDivider extends StatelessWidget {
  const OrDivider({super.key});

  @override
  Widget build(BuildContext context) {
    Widget line() => Container(height: 1, width: 112, color: OnboardingTheme.border);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        line(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text('Or', style: OnboardingTheme.inter(size: 16, color: OnboardingTheme.muted)),
        ),
        line(),
      ],
    );
  }
}

/// 3-segment progress stepper (Figma "Stepper").
/// [currentStep] is 1-based; segments 1..currentStep are filled.
class OnboardingStepper extends StatelessWidget {
  final int currentStep;
  final int totalSteps;

  const OnboardingStepper({
    super.key,
    required this.currentStep,
    this.totalSteps = 3,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(totalSteps, (i) {
        final bool filled = i < currentStep;
        return Expanded(
          child: Container(
            height: 4,
            margin: EdgeInsets.only(right: i == totalSteps - 1 ? 0 : 8),
            decoration: BoxDecoration(
              color: filled ? OnboardingTheme.primary : OnboardingTheme.stepperTrack,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      }),
    );
  }
}

/// Top bar with the centered Amina logo and an optional back chevron.
/// Mirrors the Figma header (logo centered ~top 78, back at left).
class OnboardingHeader extends StatelessWidget {
  final bool showBack;
  final VoidCallback? onBack;

  const OnboardingHeader({super.key, this.showBack = false, this.onBack});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      width: double.infinity,
      child: Stack(
        alignment: Alignment.center,
        children: [
          const AminaLogo.purple(width: 80),
          if (showBack)
            Positioned(
              left: 0,
              child: IconButton(
                onPressed: onBack ?? () => Navigator.of(context).maybePop(),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(Icons.arrow_back_ios_new,
                    size: 20, color: OnboardingTheme.textPrimary),
              ),
            ),
        ],
      ),
    );
  }
}
