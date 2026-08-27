import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petal_count/logic/logic.dart';
import 'package:petal_count/screens/settings/bip_config_card.dart';

void main() {
  late InMemoryDatabaseService db;

  setUp(() async {
    db = InMemoryDatabaseService();
    Services.db = db;
    Services.notifications = InMemoryNotificationService();
  });

  group('BipConfigCard Tests', () {
    testWidgets('renders all BIP chips and reflects active cycle selections', (
      WidgetTester tester,
    ) async {
      final cycle = Cycle(
        id: 'cycle_1',
        startDate: DateTime(2026, 8, 1),
        bipCodes: ['6C', '8Y'],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: BipConfigCard(activeCycle: cycle),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Base Infertile Pattern (BIP) Config'), findsOneWidget);
      expect(find.text('6C'), findsOneWidget);
      expect(find.text('6Y'), findsOneWidget);
      expect(find.text('8C'), findsOneWidget);
      expect(find.text('8Y'), findsOneWidget);

      final chip6C = tester.widget<FilterChip>(
        find.widgetWithText(FilterChip, '6C'),
      );
      final chip6Y = tester.widget<FilterChip>(
        find.widgetWithText(FilterChip, '6Y'),
      );
      final chip8C = tester.widget<FilterChip>(
        find.widgetWithText(FilterChip, '8C'),
      );
      final chip8Y = tester.widget<FilterChip>(
        find.widgetWithText(FilterChip, '8Y'),
      );

      expect(chip6C.selected, isTrue);
      expect(chip6Y.selected, isFalse);
      expect(chip8C.selected, isFalse);
      expect(chip8Y.selected, isTrue);
    });

    testWidgets('toggling BIP filter chips updates database BIP codes', (
      WidgetTester tester,
    ) async {
      // The default mock cycle id is DateTime(2026, 6, 1).dateKey ('2026-06-01')
      final cycleId = DateTime(2026, 6, 1).dateKey;
      final initialCycles = await db.streamCycles().first;
      final cycle = initialCycles.firstWhere((c) => c.id == cycleId);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: BipConfigCard(activeCycle: cycle),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Toggle '6Y' ON
      await tester.tap(find.text('6Y'));
      await tester.pumpAndSettle();

      final cyclesAfterAdd = await db.streamCycles().first;
      final updatedCycle = cyclesAfterAdd.firstWhere((c) => c.id == cycleId);
      expect(updatedCycle.bipCodes, containsAll(['6C', '6Y']));

      // Toggle '6C' OFF
      await tester.tap(find.text('6C'));
      await tester.pumpAndSettle();

      final cyclesAfterRemove = await db.streamCycles().first;
      final reupdatedCycle = cyclesAfterRemove.firstWhere(
        (c) => c.id == cycleId,
      );
      expect(reupdatedCycle.bipCodes, equals(['6Y']));
    });
  });
}
