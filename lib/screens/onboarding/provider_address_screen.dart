import 'package:flutter/material.dart';

import '../../config/onboarding_theme.dart';
import '../../models/onboarding_data.dart';
import '../../models/service_model.dart';
import '../../services/profile_service.dart';
import '../../services/service_service.dart';
import '../../widgets/onboarding/onboarding_widgets.dart';
import 'id_verification_screen.dart';
import 'onboarding_nav.dart';
import 'under_review_screen.dart';

/// Figma P07 - Address & Service Preferences.
/// This is the only step that submits the complete provider verification.
class ProviderAddressScreen extends StatefulWidget {
  final OnboardingData data;

  const ProviderAddressScreen({super.key, required this.data});

  @override
  State<ProviderAddressScreen> createState() => _ProviderAddressScreenState();
}

class _ProviderAddressScreenState extends State<ProviderAddressScreen> {
  late final TextEditingController _address;
  late final TextEditingController _city;
  List<ServiceCategory> _categories = [];
  final Set<int> _selected = <int>{};
  bool _loading = true;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _address = TextEditingController(text: widget.data.address);
    _city = TextEditingController(text: widget.data.city);
    _selected.addAll(widget.data.preferredServiceCategories);
    _loadCategories();
  }

  @override
  void dispose() {
    _address.dispose();
    _city.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    final categories = await ServiceService.getCategories();
    if (!mounted) return;
    setState(() {
      _categories = categories.where((category) => category.isActive).toList();
      _loading = false;
    });
  }

  Future<void> _submit() async {
    if (_address.text.trim().isEmpty || _city.text.trim().isEmpty || _selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add your address and choose at least one service category')),
      );
      return;
    }
    setState(() => _submitting = true);
    final profileResponse = await ProfileService.updateProviderProfile(
      city: _city.text.trim(),
      formattedAddress: _address.text.trim(),
      preferredServiceCategories: _selected.toList(),
    );
    if (!mounted) return;
    if (!profileResponse.success) {
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(profileResponse.error ?? 'Unable to save your preferences')),
      );
      return;
    }
    final submitResponse = await ProfileService.submitProviderVerification();
    if (!mounted) return;
    setState(() => _submitting = false);
    if (!submitResponse.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(submitResponse.error ?? 'Unable to submit for review')),
      );
      return;
    }
    widget.data.address = _address.text.trim();
    widget.data.city = _city.text.trim();
    widget.data.preferredServiceCategories = _selected.toList();
    await OnboardingNav.saveLastRole(AccountType.provider);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => UnderReviewScreen(
          onUpdateDocuments: (ctx) => Navigator.of(ctx).pushReplacement(
            MaterialPageRoute(builder: (_) => IdVerificationScreen(data: widget.data)),
          ),
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
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SizedBox(height: 28),
            OnboardingHeader(showBack: true, onBack: () => Navigator.of(context).maybePop()),
            const SizedBox(height: 24),
            const OnboardingStepper(currentStep: 4, totalSteps: 4),
            const SizedBox(height: 32),
            Text('Provider address', style: OnboardingTheme.title),
            const SizedBox(height: 6),
            Text('Add your location and preferred service categories', style: OnboardingTheme.subtitle),
            const SizedBox(height: 20),
            AppTextField(controller: _address, hint: 'Full address'),
            const SizedBox(height: 12),
            AppTextField(controller: _city, hint: 'City'),
            const SizedBox(height: 20),
            Text('Preferred services', style: OnboardingTheme.inter(size: 16, weight: FontWeight.w600)),
            const SizedBox(height: 8),
            if (_loading)
              const LinearProgressIndicator()
            else if (_categories.isEmpty)
              Text('No service categories available', style: OnboardingTheme.subtitle)
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _categories.map((category) {
                  final selected = _selected.contains(category.id);
                  return FilterChip(
                    label: Text(category.nameEn.isNotEmpty ? category.nameEn : category.name),
                    selected: selected,
                    onSelected: (value) => setState(() {
                      if (value) {
                        _selected.add(category.id);
                      } else {
                        _selected.remove(category.id);
                      }
                    }),
                    selectedColor: OnboardingTheme.selectedCardBg,
                    checkmarkColor: OnboardingTheme.primary,
                  );
                }).toList(),
              ),
            const SizedBox(height: 28),
            PrimaryButton(label: _submitting ? 'Submitting…' : 'Save & submit', onPressed: _submitting ? null : _submit),
            const SizedBox(height: 24),
          ]),
        ),
      ),
    );
  }
}
