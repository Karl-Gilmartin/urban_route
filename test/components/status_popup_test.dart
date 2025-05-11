import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:urban_route/components/status_popup.dart';

void main() {
  // Success Popup Tests
  group('StatusPopup Success Tests', () {
    testWidgets('showSuccess displays correct content', (WidgetTester tester) async {
      bool buttonPressed = false;
      void onButtonPressed() {
        buttonPressed = true;
      }

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (BuildContext context) {
              // Call showSuccess after the build is complete
              WidgetsBinding.instance.addPostFrameCallback((_) {
                StatusPopup.showSuccess(
                  context: context,
                  message: 'Success message',
                  onButtonPressed: onButtonPressed,
                );
              });
              return const Scaffold(body: SizedBox.shrink());
            },
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Success!'), findsOneWidget);
      expect(find.text('Success message'), findsOneWidget);
      expect(find.text('OK'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
      await tester.tap(find.text('OK'));
      expect(buttonPressed, true);
    });

    testWidgets('Success popup with custom title and button text', (WidgetTester tester) async {
      bool buttonPressed = false;
      void onButtonPressed() {
        buttonPressed = true;
      }

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (BuildContext context) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                StatusPopup.showSuccess(
                  context: context,
                  title: 'Custom Success',
                  message: 'Operation completed',
                  buttonText: 'Continue',
                  onButtonPressed: onButtonPressed,
                );
              });
              return const Scaffold(body: SizedBox.shrink());
            },
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify custom title and button text
      expect(find.text('Custom Success'), findsOneWidget);
      expect(find.text('Operation completed'), findsOneWidget);
      expect(find.text('Continue'), findsOneWidget);
      
      // Verify button functionality
      await tester.tap(find.text('Continue'));
      expect(buttonPressed, true);
    });

    testWidgets('Success popup has correct colors', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatusPopup(
              type: StatusType.success,
              message: 'Test message',
              onButtonPressed: () {},
            ),
          ),
        ),
      );

      final iconFinder = find.byIcon(Icons.check_circle);
      expect(iconFinder, findsOneWidget);
      final Icon icon = tester.widget<Icon>(iconFinder);
      expect(icon.color, Colors.green);
    });
  });

  // Error Popup Tests
  group('StatusPopup Error Tests', () {
    testWidgets('showError displays correct content', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (BuildContext context) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                StatusPopup.showError(
                  context: context,
                  message: 'Error message',
                  onButtonPressed: () {},
                );
              });
              return const Scaffold(body: SizedBox.shrink());
            },
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Error'), findsOneWidget);
      expect(find.text('Error message'), findsOneWidget);
      expect(find.byIcon(Icons.error), findsOneWidget);
    });

    testWidgets('Error popup has correct colors', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatusPopup(
              type: StatusType.error,
              message: 'Test error message',
              onButtonPressed: () {},
            ),
          ),
        ),
      );

      final iconFinder = find.byIcon(Icons.error);
      expect(iconFinder, findsOneWidget);
      final Icon icon = tester.widget<Icon>(iconFinder);
      expect(icon.color, Colors.red);
    });
  });

  // Warning Popup Tests
  group('StatusPopup Warning Tests', () {
    testWidgets('showWarning displays correct content', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (BuildContext context) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                StatusPopup.showWarning(
                  context: context,
                  message: 'Warning message',
                  onButtonPressed: () {},
                );
              });
              return const Scaffold(body: SizedBox.shrink());
            },
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Warning'), findsOneWidget);
      expect(find.text('Warning message'), findsOneWidget);
      expect(find.byIcon(Icons.warning), findsOneWidget);
    });

    testWidgets('Warning popup has correct colors', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatusPopup(
              type: StatusType.warning,
              message: 'Test warning message',
              onButtonPressed: () {},
            ),
          ),
        ),
      );

      final iconFinder = find.byIcon(Icons.warning);
      expect(iconFinder, findsOneWidget);
      final Icon icon = tester.widget<Icon>(iconFinder);
      expect(icon.color, Colors.orange);
    });
  });
}
