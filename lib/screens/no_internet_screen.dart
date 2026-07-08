import 'package:flutter/material.dart';
import '../services/connectivity_service.dart';
import '../l10n/app_localizations.dart';

/// 🚀 شاشة عدم الاتصال بالإنترنت
class NoInternetScreen extends StatefulWidget {
  final VoidCallback? onRetry;

  const NoInternetScreen({
    super.key,
    this.onRetry,
  });

  @override
  State<NoInternetScreen> createState() => _NoInternetScreenState();
}

class _NoInternetScreenState extends State<NoInternetScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _rocketAnimation;
  late Animation<double> _fadeAnimation;
  bool _isChecking = false;

  @override
  void initState() {
    super.initState();

    // Animation للصاروخ (يطلع ويهبط)
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _rocketAnimation = Tween<double>(
      begin: 0,
      end: -20,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _handleRetry() async {
    setState(() => _isChecking = true);

    final hasConnection = await ConnectivityService().checkConnection();

    if (mounted) {
      setState(() => _isChecking = false);

      if (hasConnection) {
        // الاتصال رجع - استدعاء callback
        widget.onRetry?.call();
      } else {
        // لسه مافيش نت - عرض رسالة
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)?.noInternetConnection ??
                  'لا يوجد اتصال بالإنترنت',
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 🚀 الصاروخ البنفسجي المتحرك
                AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(0, _rocketAnimation.value),
                      child: Opacity(
                        opacity: _fadeAnimation.value,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // الهالة البنفسجية الخارجية
                            Container(
                              width: 220,
                              height: 220,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    const Color(0xFF8B5CF6).withOpacity(0.3),
                                    const Color(0xFF8B5CF6).withOpacity(0.1),
                                    Colors.transparent,
                                  ],
                                  stops: const [0.0, 0.6, 1.0],
                                ),
                              ),
                            ),
                            // الدائرة البنفسجية الداخلية
                            Container(
                              width: 180,
                              height: 180,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    const Color(0xFF8B5CF6).withOpacity(0.2),
                                    const Color(0xFF10B981).withOpacity(0.2),
                                    const Color(0xFFC084FC).withOpacity(0.2),
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF8B5CF6).withOpacity(0.3),
                                    blurRadius: 30,
                                    spreadRadius: 5,
                                  ),
                                ],
                              ),
                            ),
                            // الصاروخ مع تدرج بنفسجي
                            ShaderMask(
                              shaderCallback: (bounds) => const LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Color(0xFF10B981),
                                  Color(0xFF8B5CF6),
                                  Color(0xFF7C3AED),
                                ],
                              ).createShader(bounds),
                              child: const Text(
                                '🚀',
                                style: TextStyle(
                                  fontSize: 120,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 40),

                // 📡 العنوان
                Text(
                  AppLocalizations.of(context)?.noInternetConnection ??
                      'لا يوجد اتصال بالإنترنت',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF1a1a1a),
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 16),

                // 📝 الوصف
                Text(
                  AppLocalizations.of(context)?.checkInternetConnection ??
                      'تحقق من اتصالك بالشبكة وحاول مرة أخرى',
                  style: TextStyle(
                    fontSize: 16,
                    color: isDark
                        ? Colors.grey[400]
                        : const Color(0xFF666666),
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 48),

                // نصائح للحل
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF1E1E1E)
                        : Colors.grey[50],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF2D2D2D)
                          : Colors.grey[200]!,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.lightbulb_outline,
                            color: const Color(0xFF8B5CF6),
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'نصائح لحل المشكلة:',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : const Color(0xFF1a1a1a),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildTip('تأكد من تشغيل Wi-Fi أو بيانات الجوال'),
                      const SizedBox(height: 12),
                      _buildTip('جرب وضع الطيران ثم أعد تشغيله'),
                      const SizedBox(height: 12),
                      _buildTip('أعد تشغيل الراوتر إذا كنت تستخدم Wi-Fi'),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // 🔄 زر إعادة المحاولة
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isChecking ? null : _handleRetry,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8B5CF6),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                      disabledBackgroundColor: Colors.grey[400],
                    ),
                    icon: _isChecking
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.refresh, size: 24),
                    label: Text(
                      _isChecking
                          ? 'جاري التحقق...'
                          : (AppLocalizations.of(context)?.retry ?? 'إعادة المحاولة'),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTip(String text) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.check_circle_outline,
          size: 18,
          color: isDark ? Colors.grey[400] : const Color(0xFF666666),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.grey[300] : const Color(0xFF666666),
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}
