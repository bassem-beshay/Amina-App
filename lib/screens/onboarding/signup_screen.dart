import 'package:flutter/material.dart';
import '../../config/onboarding_theme.dart';
import '../../models/onboarding_data.dart';
import '../../widgets/onboarding/onboarding_widgets.dart';
import 'account_type_screen.dart';
import 'otp_screen.dart';
import '../../services/auth_service.dart';
import 'onboarding_nav.dart';

/// Figma "1 · Sign up (Name + Phone)" — step 1 of 3.
class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _phone = TextEditingController();
  final _data = OnboardingData();
  bool _isLoading = false;

  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    if (_phone.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your phone number')),
      );
      return;
    }
    _data.phoneNumber = _phone.text.trim();

    setState(() => _isLoading = true);
    final sent = await AuthService.sendOtp(phoneNumber: _data.phoneNumber);
    if (!mounted) return;
    setState(() => _isLoading = false);
    if (!sent.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(sent.error ?? 'Unable to send verification code')),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => OtpScreen(
          phoneNumber: _data.phoneNumber,
          role: 'CLIENT',
          onVerified: (ctx, result) async {
            if (!result.success) return;
            if (result.user != null) {
              final role = result.user!.role.toUpperCase();
              OnboardingNav.goToHome(
                ctx,
                role == 'CLIENT' ? AccountType.user : AccountType.provider,
              );
              return;
            }
            _data.registrationToken = result.registrationToken;
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
              AppTextField(
                controller: _phone,
                hint: 'Phone Number',
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: OnboardingTheme.gap24),
              PrimaryButton(
                label: _isLoading ? 'Sending…' : 'Send code',
                onPressed: _isLoading ? null : _sendCode,
              ),
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
