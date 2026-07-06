import 'package:flutter/material.dart';
import '../../config/onboarding_theme.dart';
import '../../models/onboarding_data.dart';
import '../../widgets/onboarding/onboarding_widgets.dart';
import '../../widgets/onboarding/selectable_card.dart';
import 'company_documents_screen.dart';
import 'id_verification_screen.dart';
import 'onboarding_nav.dart';
import 'success_screen.dart';

/// Figma "3 · Account Type" (+ "3b" provider sub-panel) — step 2 of 3.
class AccountTypeScreen extends StatefulWidget {
  final OnboardingData data;

  const AccountTypeScreen({super.key, required this.data});

  @override
  State<AccountTypeScreen> createState() => _AccountTypeScreenState();
}

class _AccountTypeScreenState extends State<AccountTypeScreen> {
  late AccountType _type = widget.data.accountType;
  late ProviderType _providerType = widget.data.providerType;

  void _next() {
    widget.data.accountType = _type;
    widget.data.providerType = _providerType;

    if (_type == AccountType.user) {
      OnboardingNav.saveLastRole(AccountType.user);
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => SuccessScreen(
            onGetStarted: (ctx) => OnboardingNav.goToHome(ctx, AccountType.user),
          ),
        ),
      );
    } else {
      OnboardingNav.saveLastRole(AccountType.provider);
      final next = _providerType == ProviderType.company
          ? CompanyDocumentsScreen(data: widget.data)
          : IdVerificationScreen(data: widget.data);
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => next));
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isProvider = _type == AccountType.provider;
    return Scaffold(
      backgroundColor: OnboardingTheme.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: OnboardingTheme.sidePadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 28),
              OnboardingHeader(showBack: true, onBack: () => Navigator.of(context).maybePop()),
              const SizedBox(height: 24),
              const OnboardingStepper(currentStep: 2),
              const SizedBox(height: 40),
              Text('Choose account type', style: OnboardingTheme.title),
              const SizedBox(height: 6),
              Text("Select how you'll use Amina", style: OnboardingTheme.subtitle),
              const SizedBox(height: 24),
              SelectableCard(
                icon: Icons.person_outline,
                title: 'User',
                subtitle: 'Book and request services',
                selected: _type == AccountType.user,
                onTap: () => setState(() => _type = AccountType.user),
              ),
              const SizedBox(height: 16),
              SelectableCard(
                icon: Icons.shopping_bag_outlined,
                title: 'Provider',
                subtitle: 'Offer your services on Amina',
                selected: isProvider,
                onTap: () => setState(() => _type = AccountType.provider),
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                alignment: Alignment.topCenter,
                child: isProvider ? _providerSubPanel() : const SizedBox(width: double.infinity),
              ),
              const SizedBox(height: 32),
              PrimaryButton(label: 'Next', onPressed: _next),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _providerSubPanel() {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFFBFAFF),
          borderRadius: BorderRadius.circular(OnboardingTheme.radiusCard),
          border: Border.all(color: OnboardingTheme.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 8, left: 2),
              child: Text(
                "I'M REGISTERING AS",
                style: OnboardingTheme.inter(
                  size: 11,
                  weight: FontWeight.w600,
                  color: OnboardingTheme.muted,
                  letterSpacing: 0.6,
                ),
              ),
            ),
            SelectableCard(
              compact: true,
              icon: Icons.business_outlined,
              title: 'Company',
              subtitle: 'A registered business with tax card',
              selected: _providerType == ProviderType.company,
              onTap: () => setState(() => _providerType = ProviderType.company),
            ),
            const SizedBox(height: 8),
            SelectableCard(
              compact: true,
              icon: Icons.badge_outlined,
              title: 'Individual',
              subtitle: 'An individual service provider',
              selected: _providerType == ProviderType.individual,
              onTap: () => setState(() => _providerType = ProviderType.individual),
            ),
          ],
        ),
      ),
    );
  }
}
