import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/onboarding_data.dart';
import '../../models/user_model.dart';

/// Small helpers shared across the onboarding flow: persisting the last chosen
/// role (so a phone "Log In" can route the returning user correctly in this
/// mock flow) and routing into the app by role.
class OnboardingNav {
  static const String _lastRoleKey = 'onboarding_last_role';

  static Future<void> saveLastRole(AccountType type) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _lastRoleKey, type == AccountType.provider ? 'PROVIDER' : 'CLIENT');
  }

  static Future<AccountType> getLastRole() async {
    final prefs = await SharedPreferences.getInstance();
    final v = prefs.getString(_lastRoleKey);
    return v == 'PROVIDER' ? AccountType.provider : AccountType.user;
  }

  /// Enter the app on the role's home, clearing the onboarding stack.
  static void goToHome(BuildContext context, AccountType type) {
    final route =
        type == AccountType.provider ? '/provider-home' : '/customer-home';
    Navigator.of(context).pushNamedAndRemoveUntil(route, (r) => false);
  }

  /// Resolve the post-auth destination without changing the existing auth UI.
  /// COMPANY is a backend role in some responses and a provider_type in others,
  /// so both fields are intentionally supported here.
  static String routeForRole(String? role, {String? providerType}) {
    final normalizedRole = role?.trim().toUpperCase();
    final normalizedProviderType = providerType?.trim().toUpperCase();
    if (normalizedRole == 'ADMIN') return '/admin-dashboard';
    if (normalizedRole == 'COMPANY' || normalizedProviderType == 'COMPANY') {
      return '/company-flow-home';
    }
    if (normalizedRole == 'PROVIDER' ||
        normalizedProviderType == 'INDIVIDUAL' ||
        normalizedProviderType == 'MEMBER') {
      return '/provider-flow-home';
    }
    return '/customer-home';
  }

  static String routeForUser(User? user, {Map<String, dynamic>? userData}) {
    final data = userData ?? user?.toJson();
    final profile = data?['provider_profile'];
    final profileType = profile is Map
        ? profile['provider_type']?.toString()
        : data?['provider_type']?.toString();
    return routeForRole(user?.role ?? data?['role']?.toString(),
        providerType: profileType);
  }

  static void goToUserHome(
    BuildContext context, {
    User? user,
    Map<String, dynamic>? userData,
  }) {
    final route = routeForUser(user, userData: userData);
    Navigator.of(context).pushNamedAndRemoveUntil(route, (r) => false);
  }
}
