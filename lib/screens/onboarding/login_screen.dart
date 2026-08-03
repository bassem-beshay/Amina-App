import 'package:flutter/material.dart';
import '../../config/onboarding_theme.dart';
import '../../widgets/onboarding/onboarding_widgets.dart';
import '../../services/auth_service.dart';
import '../../models/onboarding_data.dart';
import 'onboarding_nav.dart';
import 'otp_screen.dart';
import 'signup_screen.dart';
import 'account_type_screen.dart';

/// Figma "login": phone-only sign in with social options.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phone = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_phone.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your phone number')),
      );
      return;
    }
    setState(() => _isLoading = true);
    final sent = await AuthService.sendOtp(phoneNumber: _phone.text.trim());
    if (!mounted) return;
    setState(() => _isLoading = false);
    if (!sent.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(sent.error ?? 'Unable to send verification code')),
      );
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => OtpScreen(
          phoneNumber: _phone.text.trim(),
          onVerified: (ctx, result) async {
            if (!ctx.mounted || !result.success) return;
            if (result.isNewUser && result.registrationToken != null) {
              final data = OnboardingData(
                phoneNumber: _phone.text.trim(),
                registrationToken: result.registrationToken,
              );
              Navigator.of(ctx).pushReplacement(
                MaterialPageRoute(
                    builder: (_) => AccountTypeScreen(data: data)),
              );
              return;
            }
            OnboardingNav.goToUserHome(ctx,
                user: result.user, userData: result.userData);
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
          padding: const EdgeInsets.symmetric(
              horizontal: OnboardingTheme.sidePadding),
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
              PrimaryButton(
                label: _isLoading ? 'Sending…' : 'Log In',
                onPressed: _isLoading ? null : _login,
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
                  Text("Don't have an account?",
                      style: OnboardingTheme.inter(
                          size: 14, color: OnboardingTheme.textBlack)),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const SignupScreen()),
                    ),
                    child: Text('Sign up',
                        style: OnboardingTheme.inter(
                            size: 14, color: OnboardingTheme.primary)),
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
