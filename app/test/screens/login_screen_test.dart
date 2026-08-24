import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petal_count/logic/logic.dart';
import 'package:petal_count/screens/screens.dart';

class MockLoginDatabaseService extends InMemoryDatabaseService {
  int signInCalledCount = 0;
  Completer<void>? signInCompleter;
  Object? errorToThrow;

  @override
  Future<void> signInWithGoogle() async {
    signInCalledCount++;
    if (signInCompleter != null) {
      await signInCompleter!.future;
    }
    if (errorToThrow != null) {
      throw errorToThrow!;
    }
    return super.signInWithGoogle();
  }
}

void main() {
  late MockLoginDatabaseService mockDb;

  setUp(() async {
    mockDb = MockLoginDatabaseService();
    await Services.init(dbService: mockDb);
  });

  group('LoginScreen Widget Tests', () {
    testWidgets(
      'Initial Layout & Branding: renders logo, titles, and login button',
      (WidgetTester tester) async {
        await tester.pumpWidget(const MaterialApp(home: LoginScreen()));
        await tester.pumpAndSettle();

        // Verify app branding logo
        expect(find.byIcon(Icons.filter_vintage), findsOneWidget);

        // Verify app title and subtitle
        expect(find.text('PetalCount'), findsOneWidget);
        expect(find.text('Collaborative Creighton Charting'), findsOneWidget);

        // Verify "Sign in with Google" FilledButton.icon is visible and enabled
        final buttonFinder = find.widgetWithText(
          FilledButton,
          'Sign in with Google',
        );
        expect(buttonFinder, findsOneWidget);
        expect(find.byIcon(Icons.login), findsOneWidget);

        // Verify no error text or CircularProgressIndicator is present initially
        expect(find.byType(CircularProgressIndicator), findsNothing);
      },
    );

    testWidgets(
      'Loading State Presentation: displays CircularProgressIndicator and hides button during login',
      (WidgetTester tester) async {
        mockDb.signInCompleter = Completer<void>();

        await tester.pumpWidget(const MaterialApp(home: LoginScreen()));
        await tester.pumpAndSettle();

        // Tap sign in button
        await tester.tap(
          find.widgetWithText(FilledButton, 'Sign in with Google'),
        );

        // Pump frame to advance state into loading
        await tester.pump();

        // Verify CircularProgressIndicator is displayed and sign-in button is absent
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(
          find.widgetWithText(FilledButton, 'Sign in with Google'),
          findsNothing,
        );

        // Complete the completer and settle
        mockDb.signInCompleter!.complete();
        await tester.pumpAndSettle();

        // Verify loading indicator is gone and button is restored
        expect(find.byType(CircularProgressIndicator), findsNothing);
        expect(
          find.widgetWithText(FilledButton, 'Sign in with Google'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'Successful Authentication Delegation: invokes Services.db.signInWithGoogle()',
      (WidgetTester tester) async {
        await tester.pumpWidget(const MaterialApp(home: LoginScreen()));
        await tester.pumpAndSettle();

        expect(mockDb.signInCalledCount, equals(0));

        await tester.tap(
          find.widgetWithText(FilledButton, 'Sign in with Google'),
        );
        await tester.pumpAndSettle();

        expect(mockDb.signInCalledCount, equals(1));
        expect(find.byType(CircularProgressIndicator), findsNothing);
        expect(
          find.widgetWithText(FilledButton, 'Sign in with Google'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'Error Handling & Exception Formatting: displays stripped error message in red text',
      (WidgetTester tester) async {
        mockDb.errorToThrow = Exception('Google sign-in aborted');

        await tester.pumpWidget(const MaterialApp(home: LoginScreen()));
        await tester.pumpAndSettle();

        await tester.tap(
          find.widgetWithText(FilledButton, 'Sign in with Google'),
        );
        await tester.pumpAndSettle();

        // Verify error message is displayed without 'Exception: ' prefix
        final errorFinder = find.text('Google sign-in aborted');
        expect(errorFinder, findsOneWidget);
        expect(find.text('Exception: Google sign-in aborted'), findsNothing);

        // Verify text styling has color: Colors.red
        final textWidget = tester.widget<Text>(errorFinder);
        expect(textWidget.style?.color, equals(Colors.red));

        // Verify CircularProgressIndicator is dismissed and sign-in button is restored
        expect(find.byType(CircularProgressIndicator), findsNothing);
        expect(
          find.widgetWithText(FilledButton, 'Sign in with Google'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'State Reset on Retry: clears previous error message on subsequent sign-in attempt',
      (WidgetTester tester) async {
        mockDb.errorToThrow = Exception('Network connection failed');

        await tester.pumpWidget(const MaterialApp(home: LoginScreen()));
        await tester.pumpAndSettle();

        // First attempt (fails)
        await tester.tap(
          find.widgetWithText(FilledButton, 'Sign in with Google'),
        );
        await tester.pumpAndSettle();

        expect(find.text('Network connection failed'), findsOneWidget);

        // Setup in-flight second attempt
        mockDb.errorToThrow = null;
        mockDb.signInCompleter = Completer<void>();

        // Second attempt (tapping again)
        await tester.tap(
          find.widgetWithText(FilledButton, 'Sign in with Google'),
        );
        await tester.pump();

        // Error message should be cleared immediately upon starting login
        expect(find.text('Network connection failed'), findsNothing);
        expect(find.byType(CircularProgressIndicator), findsOneWidget);

        // Finish second attempt
        mockDb.signInCompleter!.complete();
        await tester.pumpAndSettle();

        expect(find.byType(CircularProgressIndicator), findsNothing);
        expect(
          find.widgetWithText(FilledButton, 'Sign in with Google'),
          findsOneWidget,
        );
        expect(find.text('Network connection failed'), findsNothing);
        expect(mockDb.signInCalledCount, equals(2));
      },
    );
  });
}
