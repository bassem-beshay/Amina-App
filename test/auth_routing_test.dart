import 'package:flutter_test/flutter_test.dart';
import 'package:aminaapplication/screens/onboarding/onboarding_nav.dart';

void main() {
  test(
      'post-auth routing distinguishes client, individual provider and company',
      () {
    expect(OnboardingNav.routeForRole('CLIENT'), '/customer-home');
    expect(OnboardingNav.routeForRole('PROVIDER'), '/provider-flow-home');
    expect(OnboardingNav.routeForRole('PROVIDER', providerType: 'INDIVIDUAL'),
        '/provider-flow-home');
    expect(OnboardingNav.routeForRole('PROVIDER', providerType: 'COMPANY'),
        '/company-flow-home');
    expect(OnboardingNav.routeForRole('COMPANY'), '/company-flow-home');
    expect(OnboardingNav.routeForRole('ADMIN'), '/admin-dashboard');
  });
}
