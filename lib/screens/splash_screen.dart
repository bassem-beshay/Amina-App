import 'package:flutter/material.dart';
import 'dart:async';
import '../services/storage_service.dart';
import '../services/auth_service.dart';

/// شاشة Splash التي تظهر عند تشغيل التطبيق وتقوم بالتهيئة والتحقق
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  bool _isNavigating = false;
  String _loadingMessage = 'جاري التحميل...';

  @override
  void initState() {
    super.initState();

    // إعداد الأنيميشن
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
      ),
    );

    // بدء الأنيميشن
    _animationController.forward();

    // بدء التحميل والتحقق
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      // انتظار الأنيميشن تخلص أولاً
      await Future.delayed(const Duration(milliseconds: 1500));

      // 1. تحميل Auth Service
      setState(() => _loadingMessage = 'جاري تحميل البيانات...');
      await AuthService.initialize();
      await Future.delayed(const Duration(milliseconds: 500));

      // 2. التحقق من حالة تسجيل الدخول
      setState(() => _loadingMessage = 'التحقق من حسابك...');
      await _checkAuthStatus();

    } catch (e) {
      if (mounted && !_isNavigating) {
        _isNavigating = true;
        Navigator.of(context).pushReplacementNamed('/auth');
      }
    }
  }

  Future<void> _checkAuthStatus() async {
    try {
      await Future.delayed(const Duration(milliseconds: 500));

      if (!mounted || _isNavigating) return;

      // تحقق من وجود token و session
      final isLoggedIn = await AuthService.isLoggedIn();
      final token = await StorageService.getAuthToken();

      if (!mounted || _isNavigating) return;

      _isNavigating = true; // منع التنقل المتكرر

      if (isLoggedIn && token != null && token.isNotEmpty) {

        // جلب بيانات المستخدم من التخزين المحلي
        final user = await AuthService.getCurrentUser();

        if (user != null && mounted) {

          // توجيه المستخدم حسب دوره
          if (user.role.toUpperCase() == 'CLIENT') {
            Navigator.of(context).pushReplacementNamed('/customer-home');
          } else if (user.role.toUpperCase() == 'PROVIDER') {
            Navigator.of(context).pushReplacementNamed('/provider-home');
          } else if (user.role.toUpperCase() == 'ADMIN') {
            Navigator.of(context).pushReplacementNamed('/admin-dashboard');
          } else {
            // لو الدور غير معروف، اذهب لشاشة تسجيل الدخول
            Navigator.of(context).pushReplacementNamed('/auth');
          }
        } else {
          // لو فشل جلب البيانات، اذهب لشاشة تسجيل الدخول
          if (mounted) {
            Navigator.of(context).pushReplacementNamed('/auth');
          }
        }
      } else {
        // لا يوجد session، اذهب لشاشة تسجيل الدخول
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/auth');
        }
      }
    } catch (e) {
      // في حالة حدوث أي خطأ، اذهب لشاشة تسجيل الدخول
      if (mounted && !_isNavigating) {
        _isNavigating = true;
        Navigator.of(context).pushReplacementNamed('/auth');
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF4F46E5), // اللون البنفسجي
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF4F46E5),
              const Color(0xFF10B981).withOpacity(0.9),
            ],
          ),
        ),
        child: Center(
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // اللوجو
                      Container(
                        width: 150,
                        height: 150,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(35),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 30,
                              offset: const Offset(0, 15),
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(35),
                          child: Image.asset(
                            'assets/icons/app-icon.png',
                            width: 150,
                            height: 150,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              // في حالة فشل تحميل الصورة
                              return Container(
                                color: Colors.white,
                                child: const Icon(
                                  Icons.home_work,
                                  size: 80,
                                  color: Color(0xFF4F46E5),
                                ),
                              );
                            },
                          ),
                        ),
                      ),

                      const SizedBox(height: 35),

                      // اسم التطبيق بالعربي
                      const Text(
                        'منصة أمينة',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1.2,
                        ),
                      ),

                      const SizedBox(height: 8),

                      // اسم التطبيق بالإنجليزي
                      Text(
                        'Amina Platform',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.white.withOpacity(0.9),
                          letterSpacing: 0.8,
                        ),
                      ),

                      const SizedBox(height: 50),

                      // مؤشر التحميل
                      const SizedBox(
                        width: 40,
                        height: 40,
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          strokeWidth: 3,
                        ),
                      ),

                      const SizedBox(height: 20),

                      // رسالة التحميل
                      Text(
                        _loadingMessage,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
