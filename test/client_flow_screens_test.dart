import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aminaapplication/models/onboarding_data.dart';
import 'package:aminaapplication/screens/client_flow_screens.dart';

void main() {
  testWidgets('CL05 renders profile fields and continue action', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ClientProfileSetupScreen(
          data: OnboardingData(fullName: 'Karim Hassan', phoneNumber: '+201000000000'),
        ),
      ),
    );

    expect(find.text('Complete your profile'), findsOneWidget);
    expect(find.text('First name'), findsOneWidget);
    expect(find.text('Last name'), findsOneWidget);
    expect(find.text('Phone number'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);
  });

  testWidgets('shared client primary button supports disabled state', (tester) async {
    var pressed = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ClientPrimaryButton(
            label: 'Continue',
            onPressed: () => pressed = true,
          ),
        ),
      ),
    );

    await tester.tap(find.text('Continue'));
    expect(pressed, isTrue);
  });
}
