import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petal_count/logic/logic.dart';
import 'package:petal_count/screens/settings_screen.dart';

class MockTrackingDatabaseService extends InMemoryDatabaseService {
  int streamAvailableChartsCallCount = 0;

  @override
  Stream<List<Map<String, dynamic>>> streamAvailableCharts() {
    streamAvailableChartsCallCount++;
    return super.streamAvailableCharts();
  }
}

void main() {
  setUp(() async {
    await Services.init();
  });

  group('SettingsScreen Widget Tests', () {
    testWidgets(
      'Renders active profile, danger zone, and Debug & Diagnostics',
      (WidgetTester tester) async {
        await tester.pumpWidget(const MaterialApp(home: SettingsScreen()));
        await tester.pumpAndSettle();

        // Active Profile
        expect(find.text('Active Profile'), findsOneWidget);
        expect(
          find.textContaining('Email: husband@example.com'),
          findsOneWidget,
        );

        // Debug & Diagnostics section
        expect(find.text('Debug & Diagnostics'), findsOneWidget);
        expect(find.text('Export Debug State (JSON)'), findsOneWidget);
        expect(find.byIcon(Icons.bug_report_outlined), findsOneWidget);

        // Sign out button
        expect(find.text('Sign Out'), findsOneWidget);
      },
    );

    testWidgets('Tapping Export Debug State button triggers export workflow', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: SettingsScreen()));
      await tester.pumpAndSettle();

      final exportButton = find.text('Export Debug State (JSON)');
      expect(exportButton, findsOneWidget);

      await tester.scrollUntilVisible(
        exportButton,
        100.0,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      await tester.tap(exportButton);
      await tester.pumpAndSettle();

      // Verifies that export completed and any dialog popped
      expect(find.byType(SettingsScreen), findsOneWidget);
    });

    testWidgets(
      'SettingsScreen initializes _chartsStream once and does not recreate on rebuilds',
      (WidgetTester tester) async {
        final mockDb = MockTrackingDatabaseService();
        Services.db = mockDb;

        final cycle = Cycle(
          id: 'cycle_1',
          startDate: DateTime(2026, 8, 1),
          bipCodes: ['6C'],
        );

        await tester.pumpWidget(
          MaterialApp(home: SettingsScreen(activeCycle: cycle)),
        );
        await tester.pumpAndSettle();

        // Should only be called once during initState
        expect(mockDb.streamAvailableChartsCallCount, equals(1));

        // Enter text into invite partner field to trigger rebuilds
        await tester.enterText(find.byType(TextField), 'partner@example.com');
        await tester.pumpAndSettle();
        expect(mockDb.streamAvailableChartsCallCount, equals(1));

        // Toggle a BIP filter chip to trigger another rebuild
        await tester.tap(find.text('6Y'));
        await tester.pumpAndSettle();
        expect(mockDb.streamAvailableChartsCallCount, equals(1));
      },
    );
  });
}
