import 'package:flutter/material.dart';

extension AppThemeExtension on BuildContext {
  // الخلفية الرئيسية
  Color get backgroundColor => Theme.of(this).scaffoldBackgroundColor;

  // لون الكروت والعناصر البارزة
  Color get surfaceColor => Theme.of(this).colorScheme.surface;

  // لون النص الأساسي
  Color get textColor => Theme.of(this).colorScheme.onSurface;

  // لون النص الثانوي (الأخف)
  Color get secondaryTextColor =>
      Theme.of(this).brightness == Brightness.light
          ? const Color(0xFF64748B) // Slate 500
          : const Color(0xFF94A3B8); // Slate 400

  // لون الأيقونات
  Color get iconColor => Theme.of(this).iconTheme.color ?? textColor;

  // لون الحدود والفواصل
  Color get borderColor => Theme.of(this).dividerColor;

  // لون الخلفية الخفيفة (للحاويات الداخلية)
  Color get containerColor =>
      Theme.of(this).brightness == Brightness.light
          ? const Color(0xFFF1F5F9) // Slate 100
          : const Color(0xFF1E293B); // Slate 800

  // لون الأيقونات في الدوائر الصغيرة
  Color get circleIconBg =>
      Theme.of(this).brightness == Brightness.light
          ? const Color(0xFFF1F5F9)
          : const Color(0xFF0B0F19);

  // هل الثيم داكن؟
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;
}
