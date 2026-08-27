import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petal_count/logic/logic.dart';
import 'package:petal_count/screens/settings/debug_diagnostics_card.dart';

void main() {
  setUp(() async {
    await Services.init();
  });

  group('DebugDiagnosticsCard Tests', () {
    testWidgets('renders debug diagnostics header and export button', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(child: DebugDiagnosticsCard()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Debug & Diagnostics'), findsOneWidget);
      expect(find.text('Export Debug State (JSON)'), findsOneWidget);
      expect(find.byIcon(Icons.bug_report_outlined), findsOneWidget);
    });

    testWidgets('tapping export debug state button executes without error', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(child: DebugDiagnosticsCard()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Export Debug State (JSON)'));
      await tester.pumpAndSettle();

      expect(find.byType(DebugDiagnosticsCard), findsOneWidget);
    });
  });
}
