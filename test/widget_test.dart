import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_example/screens/auth/welcome_screen.dart';
import 'package:flutter/material.dart';

void main() {
  testWidgets('Welcome screen shows PetCare branding', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: WelcomeScreen()));
    expect(find.text('PetCare'), findsOneWidget);
    expect(find.text('Commencer'), findsOneWidget);
  });
}
