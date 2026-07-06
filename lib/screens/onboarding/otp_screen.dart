import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../config/onboarding_theme.dart';
import '../../widgets/onboarding/onboarding_widgets.dart';

/// Figma "2 · OTP Verification".
///
/// Mock behaviour: any 4-digit code advances the flow (the backend does not
/// support phone OTP yet). [onVerified] is invoked with a live BuildContext
/// once all four digits are entered and "Verify" is tapped.
class OtpScreen extends StatefulWidget {
  final String phoneNumber;
  final void Function(BuildContext context) onVerified;

  const OtpScreen({
    super.key,
    required this.phoneNumber,
    required this.onVerified,
  });

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  static const int _codeLength = 4;
  final List<TextEditingController> _controllers =
      List.generate(_codeLength, (_) => TextEditingController());
  final List<FocusNode> _nodes = List.generate(_codeLength, (_) => FocusNode());

  Timer? _timer;
  int _secondsLeft = 59;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _secondsLeft = 59);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_secondsLeft <= 0) {
        t.cancel();
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _controllers) {
      c.dispose();
    }
    for (final n in _nodes) {
      n.dispose();
    }
    super.dispose();
  }

  bool get _isComplete => _controllers.every((c) => c.text.isNotEmpty);

  void _onChanged(int index, String value) {
    if (value.isNotEmpty && index < _codeLength - 1) {
      _nodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _nodes[index - 1].requestFocus();
    }
    setState(() {});
  }

  void _verify() {
    // Mock: accept any 4-digit code.
    widget.onVerified(context);
  }

  String get _timerText {
    final s = _secondsLeft.toString().padLeft(2, '0');
    return '0:$s';
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
              const SizedBox(height: 56),
              Text('Verify your number', style: OnboardingTheme.title),
              const SizedBox(height: 6),
              Text(
                'Enter the 4-digit code sent to ${widget.phoneNumber}',
                style: OnboardingTheme.inter(size: 14, color: OnboardingTheme.muted),
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(_codeLength, (i) => _OtpBox(
                      controller: _controllers[i],
                      focusNode: _nodes[i],
                      onChanged: (v) => _onChanged(i, v),
                    )),
              ),
              const SizedBox(height: 16),
              Center(
                child: _secondsLeft > 0
                    ? Text('Resend code in $_timerText',
                        style: OnboardingTheme.inter(size: 14, color: OnboardingTheme.muted))
                    : GestureDetector(
                        onTap: _startTimer,
                        child: Text('Resend code',
                            style: OnboardingTheme.inter(size: 14, color: OnboardingTheme.primary)),
                      ),
              ),
              const SizedBox(height: 32),
              PrimaryButton(label: 'Verify', onPressed: _isComplete ? _verify : null),
            ],
          ),
        ),
      ),
    );
  }
}

class _OtpBox extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;

  const _OtpBox({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final bool filled = controller.text.isNotEmpty;
    return SizedBox(
      width: 72,
      height: 56,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        onChanged: onChanged,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        cursorColor: OnboardingTheme.primary,
        style: OnboardingTheme.inter(
            size: 24, weight: FontWeight.w600, color: OnboardingTheme.textPrimary),
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: InputDecoration(
          counterText: '',
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.zero,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(OnboardingTheme.radiusCard),
            borderSide: BorderSide(
              color: filled ? OnboardingTheme.primary : OnboardingTheme.border,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(OnboardingTheme.radiusCard),
            borderSide: const BorderSide(color: OnboardingTheme.primary, width: 1.5),
          ),
        ),
      ),
    );
  }
}
