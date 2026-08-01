import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../config/onboarding_theme.dart';
import '../../models/onboarding_data.dart';
import '../../services/profile_service.dart';
import '../../widgets/onboarding/onboarding_widgets.dart';
import '../../widgets/onboarding/upload_box.dart';
import 'onboarding_nav.dart';
import 'under_review_screen.dart';

/// Figma "4a · Company Documents" — step 3 of 3 (Company provider).
class CompanyDocumentsScreen extends StatefulWidget {
  final OnboardingData data;

  const CompanyDocumentsScreen({super.key, required this.data});

  @override
  State<CompanyDocumentsScreen> createState() => _CompanyDocumentsScreenState();
}

class _CompanyDocumentsScreenState extends State<CompanyDocumentsScreen> {
  bool _submitting = false;

  Future<void> _pick(void Function(String path) assign, {required bool imageOnly}) async {
    final result = await FilePicker.platform.pickFiles(
      type: imageOnly ? FileType.image : FileType.custom,
      allowedExtensions: imageOnly ? null : ['pdf', 'jpg', 'jpeg', 'png'],
    );
    final path = result?.files.single.path;
    if (path != null) setState(() => assign(path));
  }

  String? _name(String? path) => path?.split(RegExp(r'[/\\]')).last;

  Future<void> _submit() async {
    if (widget.data.taxCardPath == null || widget.data.companyLogoPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Upload the commercial register and company logo')),
      );
      return;
    }
    setState(() => _submitting = true);
    final response = await ProfileService.updateCompanyProfile(
      commercialRegisterDocument: File(widget.data.taxCardPath!),
      logo: File(widget.data.companyLogoPath!),
    );
    if (!mounted) return;
    setState(() => _submitting = false);
    if (!response.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response.error ?? 'Unable to submit company verification')),
      );
      return;
    }

    await OnboardingNav.saveLastRole(AccountType.provider);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => UnderReviewScreen(
          onUpdateDocuments: (ctx) => Navigator.of(ctx).pop(),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 28),
              OnboardingHeader(showBack: true, onBack: () => Navigator.of(context).maybePop()),
              const SizedBox(height: 24),
              const OnboardingStepper(currentStep: 3),
              const SizedBox(height: 40),
              Text('Company verification', style: OnboardingTheme.title),
              const SizedBox(height: 6),
              Text('Upload your commercial register and company logo', style: OnboardingTheme.subtitle),
              const SizedBox(height: 24),
              UploadBox(
                title: 'Commercial register',
                subtitle: 'Commercial registration document · PDF/JPG',
                fileName: _name(widget.data.taxCardPath),
                onTap: () => _pick((p) => widget.data.taxCardPath = p, imageOnly: false),
              ),
              const SizedBox(height: 16),
              UploadBox(
                title: 'Company Logo',
                subtitle: 'Square image · PNG/JPG',
                fileName: _name(widget.data.companyLogoPath),
                onTap: () => _pick((p) => widget.data.companyLogoPath = p, imageOnly: true),
              ),
              const SizedBox(height: 32),
              PrimaryButton(label: _submitting ? 'Submittingâ€¦' : 'Submit', onPressed: _submitting ? null : _submit),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
