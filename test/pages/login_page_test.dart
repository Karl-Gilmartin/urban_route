import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:urban_route/pages/login_page.dart';

void main() {
  testWidgets('LoginPage has email and password fields and a sign in button', (WidgetTester tester) async {
    // Build the LoginPage widget
    await tester.pumpWidget(
      const MaterialApp(
        home: LoginPage(),
      ),
    );

    // Check fields are present
    expect(find.byType(TextFormField), findsWidgets);
    expect(find.widgetWithText(TextFormField, 'Email'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Password'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'Sign In'), findsOneWidget);
  });
} 