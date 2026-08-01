import 'package:flutter/material.dart';

import '../../config/onboarding_theme.dart';
import '../../models/onboarding_data.dart';
import '../../services/profile_service.dart';
import '../../widgets/onboarding/onboarding_widgets.dart';
import 'id_verification_screen.dart';

/// Figma P05 - Complete Provider Profile.
/// Saves profile data only; verification is submitted later from P07.
class ProviderProfileScreen extends StatefulWidget {
  final OnboardingData data;

  const ProviderProfileScreen({super.key, required this.data});

  @override
  State<ProviderProfileScreen> createState() => _ProviderProfileScreenState();
}

class _ProviderProfileScreenState extends State<ProviderProfileScreen> {
  late final TextEditingController _firstName;
  late final TextEditingController _lastName;
  late final TextEditingController _phone;
  late final TextEditingController _city;
  late final TextEditingController _bio;
  bool _saving = false;

  Widget _labeled(String label, Widget field) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: OnboardingTheme.inter(size: 13, weight: FontWeight.w500)),
          const SizedBox(height: 8),
          field,
        ],
      );

  @override
  void initState() {
    super.initState();
    final parts = widget.data.fullName.trim().split(RegExp(r'\s+'));
    _firstName = TextEditingController(text: parts.isEmpty ? '' : parts.first);
    _lastName = TextEditingController(text: parts.length > 1 ? parts.skip(1).join(' ') : '');
    _phone = TextEditingController(text: widget.data.phoneNumber);
    _city = TextEditingController(text: widget.data.city);
    _bio = TextEditingController(text: widget.data.bio);
  }

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _phone.dispose();
    _city.dispose();
    _bio.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    if (_firstName.text.trim().isEmpty || _lastName.text.trim().isEmpty ||
        _city.text.trim().isEmpty || _bio.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Complete all profile fields to continue')),
      );
      return;
    }
    setState(() => _saving = true);
    final result = await ProfileService.updateProviderProfile(
      firstName: _firstName.text.trim(),
      lastName: _lastName.text.trim(),
      phoneNumber: widget.data.phoneNumber,
      city: _city.text.trim(),
      bio: _bio.text.trim(),
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (!result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.error ?? 'Unable to save profile')),
      );
      return;
    }
    widget.data.fullName = '${_firstName.text.trim()} ${_lastName.text.trim()}';
    widget.data.city = _city.text.trim();
    widget.data.bio = _bio.text.trim();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => IdVerificationScreen(data: widget.data)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OnboardingTheme.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: OnboardingTheme.sidePadding),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SizedBox(height: 28),
            OnboardingHeader(showBack: true, onBack: () => Navigator.of(context).maybePop()),
            const SizedBox(height: 24),
            const OnboardingStepper(currentStep: 2, totalSteps: 4),
            const SizedBox(height: 32),
            Text('Provider profile', style: OnboardingTheme.title),
            const SizedBox(height: 6),
            Text('Tell customers about your skills and experience', style: OnboardingTheme.subtitle),
            const SizedBox(height: 20),
            _labeled('First name', AppTextField(controller: _firstName, hint: 'First name')),
            const SizedBox(height: 12),
            _labeled('Last name', AppTextField(controller: _lastName, hint: 'Last name')),
            const SizedBox(height: 12),
            _labeled('Phone number', Container(
              height: OnboardingTheme.controlHeight,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.centerLeft,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(OnboardingTheme.radiusField),
                border: Border.all(color: OnboardingTheme.border),
              ),
              child: Text(_phone.text, style: OnboardingTheme.fieldText),
            )),
            const SizedBox(height: 12),
            _labeled('City', AppTextField(controller: _city, hint: 'City')),
            const SizedBox(height: 12),
            _labeled('About you', AppTextField(controller: _bio, hint: 'About you')),
            const SizedBox(height: 28),
            PrimaryButton(label: _saving ? 'Saving…' : 'Continue', onPressed: _saving ? null : _continue),
            const SizedBox(height: 24),
          ]),
        ),
      ),
    );
  }
}
