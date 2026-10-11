import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petal_count/screens/dashboard/empty_dashboard_view.dart';

void main() {
  group('EmptyDashboardView Tests', () {
    testWidgets('renders headline, description, icon, and button', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmptyDashboardView(onLogFirstObservation: () {}),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.edit_note_rounded), findsOneWidget);
      expect(find.text('No Observations Yet'), findsOneWidget);
      expect(
        find.text(
          'Log your self-reported observations to automatically track and detect your cycles.',
        ),
        findsOneWidget,
      );
      expect(
        find.widgetWithText(FilledButton, 'Log First Observation'),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('btn_log_first_observation')),
        findsOneWidget,
      );
    });

    testWidgets(
      'triggers onLogFirstObservation callback when CTA button tapped',
      (WidgetTester tester) async {
        var callbackCalled = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: EmptyDashboardView(
                onLogFirstObservation: () {
                  callbackCalled = true;
                },
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(
          find.widgetWithText(FilledButton, 'Log First Observation'),
        );
        await tester.pumpAndSettle();

        expect(callbackCalled, isTrue);
      },
    );
  });
}
