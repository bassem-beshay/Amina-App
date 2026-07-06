import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../config/onboarding_theme.dart';
import '../../models/onboarding_data.dart';
import '../../widgets/onboarding/onboarding_widgets.dart';
import '../../widgets/onboarding/upload_box.dart';
import 'onboarding_nav.dart';
import 'under_review_screen.dart';

/// Figma "4b · ID Verification" — step 3 of 3 (Individual provider).
class IdVerificationScreen extends StatefulWidget {
  final OnboardingData data;

  const IdVerificationScreen({super.key, required this.data});

  @override
  State<IdVerificationScreen> createState() => _IdVerificationScreenState();
}

class _IdVerificationScreenState extends State<IdVerificationScreen> {
  final _picker = ImagePicker();

  Future<void> _pick(void Function(String path) assign) async {
    final file = await _picker.pickImage(source: ImageSource.gallery);
    if (file != null) setState(() => assign(file.path));
  }

  String? _name(String? path) => path?.split('/').last;

  void _submit() {
    OnboardingNav.saveLastRole(AccountType.provider);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => UnderReviewScreen(
          onGetStarted: (ctx) => OnboardingNav.goToHome(ctx, AccountType.provider),
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
              Text('ID verification', style: OnboardingTheme.title),
              const SizedBox(height: 6),
              Text('Upload the front and back of your ID', style: OnboardingTheme.subtitle),
              const SizedBox(height: 24),
              UploadBox(
                title: 'ID Card — Front',
                subtitle: 'Front side of your national ID',
                fileName: _name(widget.data.idFrontPath),
                onTap: () => _pick((p) => widget.data.idFrontPath = p),
              ),
              const SizedBox(height: 16),
              UploadBox(
                title: 'ID Card — Back',
                subtitle: 'Back side of your national ID',
                fileName: _name(widget.data.idBackPath),
                onTap: () => _pick((p) => widget.data.idBackPath = p),
              ),
              const SizedBox(height: 32),
              PrimaryButton(label: 'Submit', onPressed: _submit),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
