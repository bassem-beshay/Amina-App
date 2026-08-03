import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aminaapplication/screens/client_extended_flow_screens.dart';

void main() {
  testWidgets('CL48 language settings renders all choices', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: ClientLanguageScreen()));
    expect(find.text('English'), findsOneWidget);
    expect(find.text('العربية'), findsOneWidget);
    expect(find.text('System default'), findsOneWidget);
  });

  testWidgets('CL11 companies screen has its Figma heading', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: ClientCompaniesScreen()));
    await tester.pump();
    expect(find.text('Companies'), findsOneWidget);
  });
}
