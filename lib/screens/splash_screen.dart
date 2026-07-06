import 'package:flutter/material.dart';
import 'dart:async';
import '../config/onboarding_theme.dart';
import '../services/storage_service.dart';
import '../services/auth_service.dart';
import '../widgets/onboarding/amina_logo.dart';
import 'onboarding/login_screen.dart';

/// Splash shown on launch (Figma "Splash · Enter" → "Reveal"): the Amina
/// wordmark reveals on a purple field with the tagline, then the app decides
/// where to route based on the saved session.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _logoFade;
  late Animation<double> _logoScale;
  late Animation<double> _taglineFade;
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );

    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.5, curve: Curves.easeIn)),
    );
    _logoScale = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.55, curve: Curves.easeOutBack)),
    );
    _taglineFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.45, 0.85, curve: Curves.easeIn)),
    );

    _controller.forward();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      await Future.delayed(const Duration(milliseconds: 1800));
      await AuthService.initialize();
      await _routeNext();
    } catch (_) {
      _goToLogin();
    }
  }

  Future<void> _routeNext() async {
    if (!mounted || _isNavigating) return;

    final isLoggedIn = await AuthService.isLoggedIn();
    final token = await StorageService.getAuthToken();

    if (!mounted || _isNavigating) return;

    if (isLoggedIn && token != null && token.isNotEmpty) {
      final user = await AuthService.getCurrentUser();
      if (user != null && mounted) {
        _isNavigating = true;
        final role = user.role.toUpperCase();
        if (role == 'CLIENT') {
          Navigator.of(context).pushReplacementNamed('/customer-home');
        } else if (role == 'PROVIDER') {
          Navigator.of(context).pushReplacementNamed('/provider-home');
        } else if (role == 'ADMIN') {
          Navigator.of(context).pushReplacementNamed('/admin-dashboard');
        } else {
          _goToLogin();
        }
        return;
      }
    }
    _goToLogin();
  }

  void _goToLogin() {
    if (!mounted || _isNavigating) return;
    _isNavigating = true;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OnboardingTheme.primary,
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FadeTransition(
                  opacity: _logoFade,
                  child: ScaleTransition(
                    scale: _logoScale,
                    child: const AminaLogo.white(width: 150),
                  ),
                ),
                const SizedBox(height: 22),
                FadeTransition(
                  opacity: _taglineFade,
                  child: Text(
                    'Services you can trust',
                    style: OnboardingTheme.inter(
                      size: 14,
                      weight: FontWeight.w500,
                      color: Colors.white.withOpacity(0.9),
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
