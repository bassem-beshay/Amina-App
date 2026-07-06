import 'package:flutter/material.dart';
import '../../config/onboarding_theme.dart';
import '../../widgets/onboarding/onboarding_widgets.dart';
import 'result_badge.dart';

/// Figma "6 · Under Review (Provider)".
class UnderReviewScreen extends StatelessWidget {
  final void Function(BuildContext context) onGetStarted;

  const UnderReviewScreen({super.key, required this.onGetStarted});

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
                      const ResultBadge(icon: Icons.access_time),
                      const SizedBox(height: 24),
                      Text('Account under review',
                          textAlign: TextAlign.center,
                          style: OnboardingTheme.inter(
                              size: 24, weight: FontWeight.w700, color: OnboardingTheme.textPrimary)),
                      const SizedBox(height: 10),
                      Text(
                        'Your documents were submitted successfully.',
                        textAlign: TextAlign.center,
                        style: OnboardingTheme.inter(size: 15, color: OnboardingTheme.muted),
                      ),
                      const SizedBox(height: 28),
                      _reviewBanner(),
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

  Widget _reviewBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(OnboardingTheme.radiusCard),
        border: Border.all(color: OnboardingTheme.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.access_time, size: 20, color: OnboardingTheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              "We'll review your documents within 24–48 hours. You can explore the app meanwhile.",
              style: OnboardingTheme.inter(size: 13, color: OnboardingTheme.textPrimary, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}
