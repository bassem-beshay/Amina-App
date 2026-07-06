import 'package:flutter/material.dart';
import '../../config/onboarding_theme.dart';
import '../../widgets/onboarding/onboarding_widgets.dart';
import 'result_badge.dart';

/// Figma "5 · Success (User)".
class SuccessScreen extends StatelessWidget {
  final void Function(BuildContext context) onGetStarted;

  const SuccessScreen({super.key, required this.onGetStarted});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OnboardingTheme.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: OnboardingTheme.sidePadding),
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const ResultBadge(icon: Icons.check),
                      const SizedBox(height: 24),
                      Text("You're all set!",
                          textAlign: TextAlign.center,
                          style: OnboardingTheme.inter(
                              size: 24, weight: FontWeight.w700, color: OnboardingTheme.textPrimary)),
                      const SizedBox(height: 10),
                      Text(
                        'Your Amina account has been created successfully.',
                        textAlign: TextAlign.center,
                        style: OnboardingTheme.inter(size: 15, color: OnboardingTheme.muted),
                      ),
                    ],
                  ),
                ),
              ),
              PrimaryButton(label: 'Get Started', onPressed: () => onGetStarted(context)),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
