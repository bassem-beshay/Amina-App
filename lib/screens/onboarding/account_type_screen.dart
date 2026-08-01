import 'package:flutter/material.dart';
import '../../config/onboarding_theme.dart';
import '../../models/onboarding_data.dart';
import '../../services/auth_service.dart';
import '../../widgets/onboarding/onboarding_widgets.dart';
import '../../widgets/onboarding/selectable_card.dart';
import '../client_flow_screens.dart';
import 'company_documents_screen.dart';
import 'provider_profile_screen.dart';
import 'onboarding_nav.dart';

/// Role selection is the first account-creation step after OTP verification.
class AccountTypeScreen extends StatefulWidget {
  final OnboardingData data;

  const AccountTypeScreen({super.key, required this.data});

  @override
  State<AccountTypeScreen> createState() => _AccountTypeScreenState();
}

class _AccountTypeScreenState extends State<AccountTypeScreen> {
  final _name = TextEditingController();
  final _companyName = TextEditingController();
  AccountType _accountType = AccountType.user;
  ProviderType _providerType = ProviderType.individual;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _companyName.dispose();
    super.dispose();
  }

  Future<void> _next() async {
    if (_name.text.trim().isEmpty || widget.data.registrationToken == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter your full name to continue')),
      );
      return;
    }
    final parts = _name.text.trim().split(RegExp(r'\s+'));
    final firstName = parts.first;
    final lastName = parts.skip(1).join(' ');
    final role = _accountType == AccountType.user
        ? 'CLIENT'
        : (_providerType == ProviderType.company ? 'COMPANY' : 'PROVIDER');

    setState(() => _saving = true);
    final result = await AuthService.completeRegistration(
      registrationToken: widget.data.registrationToken!,
      role: role,
      firstName: firstName,
      lastName: lastName,
      companyName: _providerType == ProviderType.company ? _companyName.text : null,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (!result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.error ?? 'Unable to complete registration')),
      );
      return;
    }

    widget.data.fullName = _name.text.trim();
    widget.data.accountType = _accountType;
    widget.data.providerType = _providerType;
    OnboardingNav.saveLastRole(_accountType);
    if (_accountType == AccountType.user) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => ClientProfileSetupScreen(data: widget.data)),
      );
    } else if (_providerType == ProviderType.company) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => CompanyDocumentsScreen(data: widget.data)),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => ProviderProfileScreen(data: widget.data)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final providerSelected = _accountType == AccountType.provider;
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
              const SizedBox(height: 20),
              SelectableCard(
                icon: Icons.person_outline,
                title: 'Client',
                subtitle: 'Book and request services',
                selected: _accountType == AccountType.user,
                onTap: () => setState(() => _accountType = AccountType.user),
              ),
              const SizedBox(height: 16),
              SelectableCard(
                icon: Icons.work_outline,
                title: 'Provider',
                subtitle: 'Offer your services on Amina',
                selected: providerSelected,
                onTap: () => setState(() => _accountType = AccountType.provider),
              ),
              if (providerSelected) ...[
                const SizedBox(height: 16),
                Text("I'm registering as", style: OnboardingTheme.inter(size: 13, color: OnboardingTheme.muted)),
                const SizedBox(height: 8),
                SelectableCard(
                  icon: Icons.business_outlined,
                  title: 'Company',
                  subtitle: 'A registered business',
                  selected: _providerType == ProviderType.company,
                  onTap: () => setState(() => _providerType = ProviderType.company),
                ),
                const SizedBox(height: 10),
                SelectableCard(
                  icon: Icons.person_pin_outlined,
                  title: 'Individual',
                  subtitle: 'An individual service provider',
                  selected: _providerType == ProviderType.individual,
                  onTap: () => setState(() => _providerType = ProviderType.individual),
                ),
                if (_providerType == ProviderType.company) ...[
                  const SizedBox(height: 12),
                  AppTextField(controller: _companyName, hint: 'Company Name'),
                ],
              ],
              const SizedBox(height: 16),
              AppTextField(controller: _name, hint: 'Full Name'),
              const SizedBox(height: 28),
              PrimaryButton(label: _saving ? 'Creating account…' : 'Next', onPressed: _saving ? null : _next),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
