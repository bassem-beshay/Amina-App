import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/onboarding_data.dart';

/// Small helpers shared across the onboarding flow: persisting the last chosen
/// role (so a phone "Log In" can route the returning user correctly in this
/// mock flow) and routing into the app by role.
class OnboardingNav {
  static const String _lastRoleKey = 'onboarding_last_role';

  static Future<void> saveLastRole(AccountType type) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastRoleKey, type == AccountType.provider ? 'PROVIDER' : 'CLIENT');
  }

  static Future<AccountType> getLastRole() async {
    final prefs = await SharedPreferences.getInstance();
    final v = prefs.getString(_lastRoleKey);
    return v == 'PROVIDER' ? AccountType.provider : AccountType.user;
  }

  /// Enter the app on the role's home, clearing the onboarding stack.
  static void goToHome(BuildContext context, AccountType type) {
    final route = type == AccountType.provider ? '/provider-home' : '/customer-home';
    Navigator.of(context).pushNamedAndRemoveUntil(route, (r) => false);
  }
}
