import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider with ChangeNotifier {
  // English only - Arabic support removed
  Locale _locale = const Locale('en');
  static const String _languageKey = 'language';

  Locale get locale => _locale;
  bool get isArabic => false;
  bool get isEnglish => true;

  LanguageProvider() {
    // No need to load preference - always English
  }

  Future<void> toggleLanguage() async {
    // Disabled - English only
  }

  Future<void> setLanguage(String languageCode) async {
    // Disabled - English only
  }
}
