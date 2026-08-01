import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../config/onboarding_theme.dart';
import '../../models/onboarding_data.dart';
import '../../services/profile_service.dart';
import '../../widgets/onboarding/onboarding_widgets.dart';
import '../../widgets/onboarding/upload_box.dart';
import 'provider_address_screen.dart';

/// Figma P06 - Identity & Health Documents.
/// This step only uploads documents. P07 performs the final submission.
class IdVerificationScreen extends StatefulWidget {
  final OnboardingData data;

  const IdVerificationScreen({super.key, required this.data});

  @override
  State<IdVerificationScreen> createState() => _IdVerificationScreenState();
}

class _IdVerificationScreenState extends State<IdVerificationScreen> {
  bool _saving = false;

  Future<void> _pick(void Function(String path) assign) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
    );
    final path = result?.files.single.path;
    if (path != null) setState(() => assign(path));
  }

  String? _name(String? path) => path?.split(RegExp(r'[/\\]')).last;

  Future<void> _continue() async {
    if (widget.data.idFrontPath == null || widget.data.idBackPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Upload both verification documents')),
      );
      return;
    }
    setState(() => _saving = true);
    final response = await ProfileService.updateProviderProfile(
      identityDocument: File(widget.data.idFrontPath!),
      healthCertificate: File(widget.data.idBackPath!),
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (!response.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response.error ?? 'Unable to save documents')),
      );
      return;
    }
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => ProviderAddressScreen(data: widget.data)),
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
            const OnboardingStepper(currentStep: 3),
            const SizedBox(height: 32),
            Text('Identity verification', style: OnboardingTheme.title),
            const SizedBox(height: 6),
            Text('Upload your ID and health certificate', style: OnboardingTheme.subtitle),
            const SizedBox(height: 20),
            UploadBox(
              title: 'Identity document',
              subtitle: 'Front of your national ID · PNG/JPG',
              fileName: _name(widget.data.idFrontPath),
              onTap: () => _pick((path) => widget.data.idFrontPath = path),
            ),
            const SizedBox(height: 12),
            UploadBox(
              title: 'Health certificate',
              subtitle: 'Valid health certificate · PNG/JPG',
              fileName: _name(widget.data.idBackPath),
              onTap: () => _pick((path) => widget.data.idBackPath = path),
            ),
            const SizedBox(height: 28),
            PrimaryButton(label: _saving ? 'Saving…' : 'Continue', onPressed: _saving ? null : _continue),
            const SizedBox(height: 24),
          ]),
        ),
      ),
    );
  }
}
