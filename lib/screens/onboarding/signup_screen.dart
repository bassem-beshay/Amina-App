import 'package:flutter/material.dart';
import '../../config/onboarding_theme.dart';
import '../../models/onboarding_data.dart';
import '../../widgets/onboarding/onboarding_widgets.dart';
import 'account_type_screen.dart';
import 'otp_screen.dart';

/// Figma "1 · Sign up (Name + Phone)" — step 1 of 3.
class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _data = OnboardingData();

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  void _sendCode() {
    if (_name.text.trim().isEmpty || _phone.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your name and phone number')),
      );
      return;
    }
    _data.fullName = _name.text.trim();
    _data.phoneNumber = _phone.text.trim();

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => OtpScreen(
          phoneNumber: _data.phoneNumber,
          onVerified: (ctx) {
            Navigator.of(ctx).push(
              MaterialPageRoute(builder: (_) => AccountTypeScreen(data: _data)),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OnboardingTheme.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: OnboardingTheme.sidePadding),
          child: Column(
            children: [
              const SizedBox(height: 28),
              const OnboardingHeader(),
              const SizedBox(height: 24),
              const OnboardingStepper(currentStep: 1),
              const SizedBox(height: 40),
              AppTextField(controller: _name, hint: 'Full Name'),
              const SizedBox(height: OnboardingTheme.gap16),
              AppTextField(
                controller: _phone,
                hint: 'Phone Number',
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: OnboardingTheme.gap24),
              PrimaryButton(label: 'Send code', onPressed: _sendCode),
              const SizedBox(height: OnboardingTheme.gap32),
              const OrDivider(),
              const SizedBox(height: OnboardingTheme.gap32),
              SocialButton(
                assetIcon: 'assets/images/google_icon.svg',
                label: 'Continue with Google',
                onPressed: () {},
              ),
              const SizedBox(height: OnboardingTheme.gap16),
              SocialButton(
                assetIcon: 'assets/images/apple_icon.svg',
                label: 'Continue with Apple',
                onPressed: () {},
              ),
              const SizedBox(height: OnboardingTheme.gap24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Already have an account?',
                      style: OnboardingTheme.inter(size: 14, color: OnboardingTheme.textBlack)),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => Navigator.of(context).maybePop(),
                    child: Text('Log in',
                        style: OnboardingTheme.inter(size: 14, color: OnboardingTheme.primary)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
