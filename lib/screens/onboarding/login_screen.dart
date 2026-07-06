import 'package:flutter/material.dart';
import '../../config/onboarding_theme.dart';
import '../../widgets/onboarding/onboarding_widgets.dart';
import 'onboarding_nav.dart';
import 'otp_screen.dart';
import 'signup_screen.dart';

/// Figma "login": phone-only sign in with social options.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phone = TextEditingController();

  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  void _login() {
    if (_phone.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your phone number')),
      );
      return;
    }
    // Mock flow: verify by OTP, then route by the last known role.
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => OtpScreen(
          phoneNumber: _phone.text.trim(),
          onVerified: (ctx) async {
            final role = await OnboardingNav.getLastRole();
            if (ctx.mounted) OnboardingNav.goToHome(ctx, role);
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
              const SizedBox(height: 72),
              AppTextField(
                controller: _phone,
                hint: 'Phone Number',
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: OnboardingTheme.gap24),
              PrimaryButton(label: 'Log In', onPressed: _login),
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
                  Text("Don't have an account?",
                      style: OnboardingTheme.inter(size: 14, color: OnboardingTheme.textBlack)),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const SignupScreen()),
                    ),
                    child: Text('Sign up',
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
