import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import '../services/push_notification_service.dart';
import '../services/api_client.dart';
import '../l10n/app_localizations.dart';
import '../providers/theme_provider.dart';
import 'email_verification_screen.dart';
import '../widgets/connectivity_button.dart';

class AuthScreen extends StatefulWidget {
  final bool isLogin;
  const AuthScreen({super.key, this.isLogin = true});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  String _email = '';
  String _password = '';
  String _firstName = '';
  String _lastName = '';
  String _phoneNumber = '';
  String _role = 'CLIENT';
  bool _obscure = true;
  late bool _isLogin;
  bool _isLoading = false;
  bool _rememberMe = false;

  // OTP Login State
  int _loginStep = 1; // 1 = enter phone, 2 = enter OTP
  String _loginPhoneNumber = '';
  String _otpCode = '';
  final TextEditingController _loginPhoneController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();

  final FocusNode _firstNameFocus = FocusNode();
  final FocusNode _lastNameFocus = FocusNode();
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _phoneFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();
  final FocusNode _loginPhoneFocus = FocusNode();
  final FocusNode _otpFocus = FocusNode();

  // Animation controllers
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // أنيميشن إضافي للوجو
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // أنيميشن الدوران
  late AnimationController _rotationController;
  late Animation<double> _rotationAnimation;

  // Text controllers for email and password
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // قائمة الأدوار المتاحة
  List<Map<String, String>> _getRoles(BuildContext context) {
    return [
      {
        'value': 'CLIENT',
        'label': AppLocalizations.of(context)?.client ?? 'عميل'
      },
      {
        'value': 'PROVIDER',
        'label': AppLocalizations.of(context)?.serviceProvider ?? 'مقدم خدمة'
      },
    ];
  }

  @override
  void initState() {
    super.initState();
    _isLogin = widget.isLogin;
    _loadRememberedCredentials();

    // تهيئة الأنيميشن الرئيسي
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    // أنيميشن النبض المستمر للوجو
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    // أنيميشن الدوران الخفيف
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat();

    _rotationAnimation = Tween<double>(
      begin: -0.02,
      end: 0.02,
    ).animate(CurvedAnimation(
      parent: _rotationController,
      curve: Curves.easeInOutSine,
    ));

    // بدء الأنيميشن الرئيسي
    _animationController.forward();
  }

  // Load remembered credentials if "Remember Me" was checked
  Future<void> _loadRememberedCredentials() async {
    final rememberMe = await StorageService.getRememberMe();
    if (rememberMe && _isLogin) {
      final phone = await StorageService.getRememberedPhone();

      if (phone != null) {
        setState(() {
          _loginPhoneNumber = phone;
          _rememberMe = true;
          _loginPhoneController.text = phone;
        });
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pulseController.dispose();
    _rotationController.dispose();
    _firstNameFocus.dispose();
    _lastNameFocus.dispose();
    _emailFocus.dispose();
    _phoneFocus.dispose();
    _passwordFocus.dispose();
    _loginPhoneFocus.dispose();
    _otpFocus.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _loginPhoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  void _toggleMode() {
    setState(() {
      _isLogin = !_isLogin;
      _formKey.currentState?.reset();
      _firstName = '';
      _lastName = '';
      _email = '';
      _phoneNumber = '';
      _role = 'CLIENT';
      // Reset OTP state
      _loginStep = 1;
      _loginPhoneNumber = '';
      _otpCode = '';
      _loginPhoneController.clear();
      _otpController.clear();
    });

    // إعادة تشغيل الأنيميشن
    _animationController.reset();
    _animationController.forward();
  }

  // Send OTP for login step 1
  Future<void> _sendOtp() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    _formKey.currentState?.save();

    setState(() => _isLoading = true);

    try {
      final result = await AuthService.sendOtp(phoneNumber: _loginPhoneNumber);

      if (!mounted) return;

      if (result.success) {
        setState(() {
          _loginStep = 2;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message ?? 'تم إرسال رمز التحقق'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.error ?? 'فشل إرسال رمز التحقق'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Verify OTP for login step 2
  Future<void> _verifyOtp() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    _formKey.currentState?.save();

    setState(() => _isLoading = true);

    try {
      final result = await AuthService.verifyOtp(
        phoneNumber: _loginPhoneNumber,
        otpCode: _otpCode,
        rememberMe: _rememberMe,
      );

      if (!mounted) return;

      if (result.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                AppLocalizations.of(context)?.loginSuccess ??
                'Logged in successfully'),
            backgroundColor: Colors.green,
          ),
        );

        // تهيئة Push Notifications بعد تسجيل الدخول الناجح
        try {
          await PushNotificationService().initialize();
        } catch (e) {
        }

        // التوجيه حسب الدور
        final userRole =
            result.user?.role ?? result.userData?['role'] ?? 'CLIENT';
        final userRoleUpper = userRole.toString().toUpperCase();

        if (userRoleUpper == 'ADMIN') {
          Navigator.of(context).pushReplacementNamed('/admin-dashboard');
        } else if (userRoleUpper == 'PROVIDER') {
          Navigator.of(context).pushReplacementNamed('/provider-home');
        } else {
          Navigator.of(context).pushReplacementNamed('/customer-home');
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.error ?? 'رمز التحقق غير صحيح'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    _formKey.currentState?.save();

    // OTP login flow
    if (_isLogin) {
      if (_loginStep == 1) {
        await _sendOtp();
      } else {
        await _verifyOtp();
      }
      return;
    }

    setState(() => _isLoading = true);

    try {
      AuthResult result;

      // التسجيل فقط (تسجيل الدخول يتم عبر OTP أعلاه)
      if (_role == 'CLIENT') {
        result = await AuthService.registerClient(
          email: _email,
          password: _password,
          firstName: _firstName,
          lastName: _lastName,
          phoneNumber: _phoneNumber,
        );
      } else {
        result = await AuthService.registerProvider(
          email: _email,
          password: _password,
          firstName: _firstName,
          lastName: _lastName,
          phoneNumber: _phoneNumber,
        );
      }

      if (!mounted) return;

      if (result.success) {
        // Check if email verification is required
        if (result.requiresVerification && result.email != null) {
          // Navigate to email verification screen
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.message ?? 'تم إرسال كود التحقق إلى بريدك الإلكتروني'),
              backgroundColor: Colors.green,
            ),
          );

          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => EmailVerificationScreen(
                email: result.email!,
                userType: _role.toLowerCase(),
              ),
            ),
          );
          return;
        }

        // Normal login/registration (already verified)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                AppLocalizations.of(context)?.loginSuccess ??
                'Logged in successfully'),
            backgroundColor: Colors.green,
          ),
        );

        // تهيئة Push Notifications بعد تسجيل الدخول الناجح
        if (ApiClient.authToken != null) {
        }

        try {
          await PushNotificationService().initialize();
        } catch (e) {
        }

        // التوجيه حسب الدور
        final userRole =
            result.user?.role ?? result.userData?['role'] ?? 'CLIENT';
        final userRoleUpper = userRole.toString().toUpperCase();

        if (userRoleUpper == 'ADMIN') {
          // أدمن → Admin Dashboard
          Navigator.of(context).pushReplacementNamed('/admin-dashboard');
        } else if (userRoleUpper == 'PROVIDER') {
          // مقدم خدمة → Provider Home
          Navigator.of(context).pushReplacementNamed('/provider-home');
        } else {
          // عميل → Customer Home
          Navigator.of(context).pushReplacementNamed('/customer-home');
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.error ??
                AppLocalizations.of(context)?.errorOccurred ??
                'حدث خطأ'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '${AppLocalizations.of(context)?.error ?? 'خطأ'}: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    // عرض dialog لاختيار نوع الحساب
    final selectedRole = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)?.chooseAccountType ??
            'اختر نوع الحساب'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(AppLocalizations.of(context)?.pleaseSelectAccountType ??
                'يرجى تحديد نوع حسابك قبل المتابعة'),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.person),
              title: Text(AppLocalizations.of(context)?.client ?? 'عميل'),
              subtitle: Text(
                  AppLocalizations.of(context)?.lookingForHomeServices ??
                      'أبحث عن خدمات منزلية'),
              onTap: () => Navigator.pop(context, 'CLIENT'),
            ),
            ListTile(
              leading: const Icon(Icons.work),
              title: Text(
                  AppLocalizations.of(context)?.serviceProvider ?? 'مقدم خدمة'),
              subtitle: Text(
                  AppLocalizations.of(context)?.provideHomeServices ??
                      'أقدم خدمات منزلية'),
              onTap: () => Navigator.pop(context, 'PROVIDER'),
            ),
          ],
        ),
      ),
    );

    if (selectedRole == null) return;

    setState(() => _isLoading = true);

    try {
      final result = await AuthService.signInWithGoogle(role: selectedRole);

      if (!mounted) return;

      if (result.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                AppLocalizations.of(context)?.loginSuccess ??
                'Logged in successfully'),
            backgroundColor: Colors.green,
          ),
        );

        // تهيئة Push Notifications بعد تسجيل الدخول الناجح بـ Google
        if (ApiClient.authToken != null) {
        }

        try {
          await PushNotificationService().initialize();
        } catch (e) {
        }

        // التوجيه حسب الدور
        final userRole =
            result.user?.role ?? result.userData?['role'] ?? 'CLIENT';
        final userRoleUpper = userRole.toString().toUpperCase();

        if (userRoleUpper == 'ADMIN') {
          Navigator.of(context).pushReplacementNamed('/admin-dashboard');
        } else if (userRoleUpper == 'PROVIDER') {
          Navigator.of(context).pushReplacementNamed('/provider-home');
        } else {
          Navigator.of(context).pushReplacementNamed('/customer-home');
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.error ??
                AppLocalizations.of(context)?.loginFailed ??
                'فشل تسجيل الدخول'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '${AppLocalizations.of(context)?.error ?? 'خطأ'}: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // دالة للتحقق من صحة رقم الهاتف
  String? _validatePhoneNumber(String? value) {
    if (value == null || value.isEmpty) {
      return AppLocalizations.of(context)?.fieldRequired ??
          'من فضلك أدخل رقم الهاتف';
    }

    // تحقق أساسي من تنسيق رقم الهاتف
    final phoneRegex = RegExp(r'^[+]*[(]{0,1}[0-9]{1,4}[)]{0,1}[-\s\./0-9]*$');
    if (!phoneRegex.hasMatch(value)) {
      return AppLocalizations.of(context)?.invalidPhone ?? 'أدخل رقم هاتف صالح';
    }

    if (value.length < 8) {
      return AppLocalizations.of(context)?.invalidPhone ??
          'رقم الهاتف يجب أن يكون 8 أرقام على الأقل';
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: themeProvider.isDarkMode
                ? [
                    const Color(0xFF4F46E5).withOpacity(0.1),
                    const Color(0xFF121212),
                  ]
                : [
                    const Color(0xFF4F46E5).withOpacity(0.05),
                    Colors.white,
                  ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // المحتوى الأصلي (يجب أن يكون أول عنصر)
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 500),
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: Card(
                      elevation: 8,
                      color: theme.colorScheme.surface,
                      shadowColor: const Color(0xFF4F46E5).withOpacity(0.2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Header مع لوجو محسن
                            Column(
                              children: [
                                // اللوجو المحسن مع أنيميشنات متعددة
                                AnimatedBuilder(
                                  animation: Listenable.merge([
                                    _pulseAnimation,
                                    _rotationAnimation,
                                  ]),
                                  builder: (context, child) {
                                    return TweenAnimationBuilder<double>(
                                      tween: Tween(begin: 0.8, end: 1.0),
                                      duration:
                                          const Duration(milliseconds: 600),
                                      curve: Curves.elasticOut,
                                      builder: (context, scaleValue, _) {
                                        return Transform.scale(
                                          scale: scaleValue *
                                              _pulseAnimation.value,
                                          child: Transform.rotate(
                                            angle: _rotationAnimation.value,
                                            child: Container(
                                              width: 90,
                                              height: 90,
                                              decoration: BoxDecoration(
                                                gradient: const LinearGradient(
                                                  begin: Alignment.topLeft,
                                                  end: Alignment.bottomRight,
                                                  colors: [
                                                    Color(0xFF818CF8),
                                                    Color(0xFF4F46E5),
                                                  ],
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(24),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color:
                                                        const Color(0xFF4F46E5)
                                                            .withOpacity(0.3 *
                                                                _pulseAnimation
                                                                    .value),
                                                    blurRadius: 20 *
                                                        _pulseAnimation.value,
                                                    offset: const Offset(0, 8),
                                                  ),
                                                ],
                                              ),
                                              child: Stack(
                                                alignment: Alignment.center,
                                                children: [
                                                  // الأيقونة الخلفية
                                                  Icon(
                                                    Icons
                                                        .cleaning_services_rounded,
                                                    size: 48,
                                                    color: Colors.white
                                                        .withOpacity(0.3),
                                                  ),
                                                  // الأيقونة الأمامية
                                                  Icon(
                                                    Icons.home_work_rounded,
                                                    size: 42,
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .surface,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    );
                                  },
                                ),
                                const SizedBox(height: 24),
                                // العنوان
                                Text(
                                  _isLogin
                                      ? (AppLocalizations.of(context)
                                              ?.welcomeBack ??
                                          'مرحباً بك مجدداً')
                                      : (AppLocalizations.of(context)?.joinUs ??
                                          'انضم إلينا'),
                                  style:
                                      theme.textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF4F46E5),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _isLogin
                                      ? (AppLocalizations.of(context)
                                              ?.gladToSeeYouAgain ??
                                          'سُعدنا برؤيتك مجدداً، سجل دخولك للمتابعة')
                                      : (AppLocalizations.of(context)
                                              ?.createNewAccount ??
                                          'أنشئ حساباً جديداً وابدأ رحلتك معنا'),
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),

                            const SizedBox(height: 32),

                            // Form
                            Form(
                              key: _formKey,
                              child: Column(
                                children: [
                                  // ===== Login Mode: Phone + OTP =====
                                  if (_isLogin) ...[
                                    if (_loginStep == 1) ...[
                                      // الخطوة 1: إدخال رقم الهاتف
                                      TextFormField(
                                        controller: _loginPhoneController,
                                        decoration: InputDecoration(
                                          labelText: AppLocalizations.of(context)
                                                  ?.phoneNumber ??
                                              'رقم الهاتف',
                                          hintText: 'أدخل رقم هاتفك المسجل',
                                          prefixIcon: const Icon(Icons.phone),
                                        ),
                                        keyboardType: TextInputType.phone,
                                        textInputAction: TextInputAction.done,
                                        focusNode: _loginPhoneFocus,
                                        onFieldSubmitted: (_) => _submit(),
                                        onSaved: (v) => _loginPhoneNumber = v ?? '',
                                        validator: _validatePhoneNumber,
                                      ),
                                    ] else ...[
                                      // الخطوة 2: عرض الرقم + إدخال OTP
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF4F46E5).withOpacity(0.05),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(Icons.phone, color: Color(0xFF4F46E5)),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                _loginPhoneNumber,
                                                style: theme.textTheme.bodyLarge?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            TextButton(
                                              onPressed: () {
                                                setState(() {
                                                  _loginStep = 1;
                                                  _otpController.clear();
                                                  _otpCode = '';
                                                });
                                              },
                                              child: const Text('تغيير'),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'أدخل رمز التحقق المرسل إلى هاتفك',
                                        style: theme.textTheme.bodyMedium?.copyWith(
                                          color: Colors.grey[600],
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 12),
                                      TextFormField(
                                        controller: _otpController,
                                        decoration: const InputDecoration(
                                          labelText: 'رمز التحقق',
                                          hintText: '1234',
                                          prefixIcon: Icon(Icons.lock_outline),
                                        ),
                                        keyboardType: TextInputType.number,
                                        textInputAction: TextInputAction.done,
                                        focusNode: _otpFocus,
                                        maxLength: 4,
                                        textAlign: TextAlign.center,
                                        style: theme.textTheme.headlineSmall?.copyWith(
                                          letterSpacing: 8,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        onFieldSubmitted: (_) => _submit(),
                                        onSaved: (v) => _otpCode = v ?? '',
                                        validator: (v) => (v == null || v.length != 4)
                                            ? 'أدخل رمز التحقق المكون من 4 أرقام'
                                            : null,
                                      ),
                                      const SizedBox(height: 8),
                                      Align(
                                        alignment: Alignment.center,
                                        child: TextButton(
                                          onPressed: _isLoading ? null : () => _sendOtp(),
                                          child: const Text('إعادة إرسال الرمز'),
                                        ),
                                      ),
                                    ],

                                    // Remember Me checkbox
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 8.0),
                                      child: Row(
                                        children: [
                                          Checkbox(
                                            value: _rememberMe,
                                            onChanged: (value) {
                                              setState(() {
                                                _rememberMe = value ?? false;
                                              });
                                            },
                                            materialTapTargetSize:
                                                MaterialTapTargetSize
                                                    .shrinkWrap,
                                            visualDensity:
                                                VisualDensity.compact,
                                          ),
                                          Expanded(
                                            child: GestureDetector(
                                              onTap: () {
                                                setState(() {
                                                  _rememberMe = !_rememberMe;
                                                });
                                              },
                                              child: Text(
                                                AppLocalizations.of(context)
                                                        ?.rememberMe ??
                                                    'تذكرني',
                                                style:
                                                    theme.textTheme.bodyMedium,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],

                                  // ===== Registration Mode: Original fields =====
                                  if (!_isLogin) ...[
                                    // حقل الاسم الأول
                                    TextFormField(
                                      decoration: InputDecoration(
                                        labelText: AppLocalizations.of(context)
                                                ?.firstName ??
                                            'الاسم الأول',
                                      ),
                                      textInputAction: TextInputAction.next,
                                      focusNode: _firstNameFocus,
                                      onFieldSubmitted: (_) => FocusScope.of(
                                        context,
                                      ).requestFocus(_lastNameFocus),
                                      onSaved: (v) => _firstName = v ?? '',
                                      validator: (v) =>
                                          (v == null || v.trim().length < 2)
                                              ? (AppLocalizations.of(context)
                                                      ?.enterValidName ??
                                                  'من فضلك أدخل اسمًا صحيحًا')
                                              : null,
                                    ),
                                    const SizedBox(height: 12),

                                    // حقل الاسم الأخير
                                    TextFormField(
                                      decoration: InputDecoration(
                                        labelText: AppLocalizations.of(context)
                                                ?.lastName ??
                                            'الاسم الأخير',
                                      ),
                                      textInputAction: TextInputAction.next,
                                      focusNode: _lastNameFocus,
                                      onFieldSubmitted: (_) => FocusScope.of(
                                        context,
                                      ).requestFocus(_emailFocus),
                                      onSaved: (v) => _lastName = v ?? '',
                                      validator: (v) =>
                                          (v == null || v.trim().length < 2)
                                              ? (AppLocalizations.of(context)
                                                      ?.enterValidName ??
                                                  'من فضلك أدخل اسمًا صحيحًا')
                                              : null,
                                    ),
                                    const SizedBox(height: 12),

                                    // حقل البريد الإلكتروني
                                    TextFormField(
                                      controller: _emailController,
                                      decoration: InputDecoration(
                                        labelText:
                                            AppLocalizations.of(context)?.email ??
                                                'البريد الإلكتروني',
                                      ),
                                      keyboardType: TextInputType.emailAddress,
                                      textInputAction: TextInputAction.next,
                                      focusNode: _emailFocus,
                                      onFieldSubmitted: (_) => FocusScope.of(context)
                                              .requestFocus(_phoneFocus),
                                      onSaved: (v) => _email = v ?? '',
                                      validator: (v) =>
                                          (v == null || !v.contains('@'))
                                              ? (AppLocalizations.of(context)
                                                      ?.enterValidEmail ??
                                                  'أدخل بريدًا إلكترونيًا صالحًا')
                                              : null,
                                    ),
                                    const SizedBox(height: 12),

                                    // حقل رقم الهاتف (مطلوب للتسجيل)
                                    TextFormField(
                                      decoration: InputDecoration(
                                        labelText: AppLocalizations.of(context)
                                                ?.phoneNumber ??
                                            'رقم الهاتف',
                                        hintText: AppLocalizations.of(context)
                                                ?.enterPhoneNumber ??
                                            'أدخل رقم هاتفك',
                                      ),
                                      keyboardType: TextInputType.phone,
                                      textInputAction: TextInputAction.next,
                                      focusNode: _phoneFocus,
                                      onFieldSubmitted: (_) => FocusScope.of(
                                        context,
                                      ).requestFocus(_passwordFocus),
                                      onSaved: (v) => _phoneNumber = v ?? '',
                                      validator: _validatePhoneNumber,
                                    ),
                                    const SizedBox(height: 12),

                                    // حقل اختيار الدور (مطلوب للتسجيل)
                                    DropdownButtonFormField<String>(
                                      decoration: InputDecoration(
                                        labelText: AppLocalizations.of(context)
                                                ?.accountType ??
                                            'نوع الحساب',
                                      ),
                                      value: _role,
                                      items: _getRoles(context).map((role) {
                                        return DropdownMenuItem(
                                          value: role['value'],
                                          child: Text(role['label']!),
                                        );
                                      }).toList(),
                                      onChanged: (value) {
                                        setState(() {
                                          _role = value ?? 'CLIENT';
                                        });
                                      },
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return AppLocalizations.of(context)
                                                  ?.fieldRequired ??
                                              'من فضلك اختر نوع الحساب';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 12),

                                    // حقل كلمة المرور (للتسجيل فقط)
                                    TextFormField(
                                      controller: _passwordController,
                                      decoration: InputDecoration(
                                        labelText: AppLocalizations.of(context)
                                                ?.password ??
                                            'كلمة المرور',
                                        suffixIcon: IconButton(
                                          icon: Icon(
                                            _obscure
                                                ? Icons.visibility
                                                : Icons.visibility_off,
                                          ),
                                          onPressed: () => setState(
                                              () => _obscure = !_obscure),
                                          tooltip: _obscure
                                              ? (AppLocalizations.of(context)
                                                      ?.showPassword ??
                                                  'أظهر كلمة المرور')
                                              : (AppLocalizations.of(context)
                                                      ?.hidePassword ??
                                                  'أخفِ كلمة المرور'),
                                        ),
                                      ),
                                      obscureText: _obscure,
                                      focusNode: _passwordFocus,
                                      textInputAction: TextInputAction.done,
                                      onFieldSubmitted: (_) => _submit(),
                                      onSaved: (v) => _password = v ?? '',
                                      validator: (v) => (v == null ||
                                              v.length < 6)
                                          ? (AppLocalizations.of(context)
                                                  ?.passwordMinLength ??
                                              'يجب أن تكون كلمة المرور 6 أحرف على الأقل')
                                          : null,
                                    ),
                                  ],

                                  const SizedBox(height: 20),

                                  // زر الإرسال مع أنيميشن
                                  TweenAnimationBuilder<double>(
                                    tween: Tween(begin: 1.0, end: 1.0),
                                    duration: const Duration(milliseconds: 200),
                                    builder: (context, scale, child) {
                                      return Transform.scale(
                                        scale: scale,
                                        child: Container(
                                          width: double.infinity,
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            boxShadow: [
                                              BoxShadow(
                                                color: theme.colorScheme.primary
                                                    .withOpacity(0.3),
                                                blurRadius: 8,
                                                offset: const Offset(0, 4),
                                              ),
                                            ],
                                          ),
                                          child: ConnectivityButton(
                                            onPressed: _isLoading
                                                ? null
                                                : () => _submit(),
                                            style: ElevatedButton.styleFrom(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                vertical: 14,
                                              ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              elevation: 0,
                                            ),
                                            child: _isLoading
                                                ? const SizedBox(
                                                    height: 18,
                                                    width: 18,
                                                    child:
                                                        CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                      color: Colors.white,
                                                    ),
                                                  )
                                                : Text(
                                                    _isLogin
                                                        ? (_loginStep == 1
                                                            ? 'إرسال رمز التحقق'
                                                            : 'تحقق ودخول')
                                                        : (AppLocalizations.of(
                                                                    context)
                                                                ?.createAccount ??
                                                            'إنشاء حساب'),
                                                    style: const TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),

                                  const SizedBox(height: 12),

                                  // زر التبديل بين التسجيل والدخول
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        _isLogin
                                            ? (AppLocalizations.of(context)
                                                    ?.dontHaveAccount ??
                                                'لا تملك حساباً؟')
                                            : (AppLocalizations.of(context)
                                                    ?.alreadyHaveAccount ??
                                                'هل لديك حساب؟'),
                                      ),
                                      ConnectivityTextButton(
                                        onPressed: _toggleMode,
                                        child: Text(
                                          _isLogin
                                              ? (AppLocalizations.of(context)
                                                      ?.register ??
                                                  'إنشاء الآن')
                                              : (AppLocalizations.of(context)
                                                      ?.login ??
                                                  'تسجيل الدخول'),
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 16),

                                  // فاصل "أو"
                                  Row(
                                    children: [
                                      const Expanded(child: Divider()),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 16),
                                        child: Text(
                                          AppLocalizations.of(context)?.or ??
                                              'أو',
                                          style: theme.textTheme.bodyMedium
                                              ?.copyWith(
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ),
                                      const Expanded(child: Divider()),
                                    ],
                                  ),

                                  const SizedBox(height: 16),

                                  // زر تسجيل الدخول عبر Google
                                  SizedBox(
                                    width: double.infinity,
                                    child: OutlinedButton.icon(
                                      onPressed:
                                          _isLoading ? null : _signInWithGoogle,
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 14),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        side: BorderSide(
                                          color: theme.colorScheme.outline,
                                        ),
                                      ),
                                      icon: Icon(
                                        Icons.g_mobiledata,
                                        size: 32,
                                        color: _isLoading
                                            ? Colors.grey
                                            : Colors.red,
                                      ),
                                      label: Text(
                                        AppLocalizations.of(context)
                                                ?.signInWithGoogle ??
                                            'تسجيل الدخول عبر Google',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: _isLoading
                                              ? Colors.grey
                                              : theme.colorScheme.onSurface,
                                        ),
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 8),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
                ),
              ),

              // Theme toggle button في الزاوية العلوية اليمنى (آخر عنصر ليكون فوق كل شيء)
              Positioned(
                top: 16,
                right: 16,
                child: Material(
                  elevation: 8,
                  borderRadius: BorderRadius.circular(12),
                  color: theme.colorScheme.surface,
                  shadowColor: const Color(0xFF4F46E5).withOpacity(0.3),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () async {
                      await themeProvider.toggleTheme();
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      child: Icon(
                        themeProvider.isDarkMode
                            ? Icons.light_mode_rounded
                            : Icons.dark_mode_rounded,
                        color: themeProvider.isDarkMode
                            ? const Color(0xFFFFD700)
                            : const Color(0xFF4F46E5),
                        size: 28,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
        );
      },
    );
  }
}
