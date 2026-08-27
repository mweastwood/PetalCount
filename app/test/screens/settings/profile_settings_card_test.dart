import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petal_count/logic/logic.dart';
import 'package:petal_count/screens/settings/profile_settings_card.dart';

void main() {
  late InMemoryDatabaseService db;

  setUp(() async {
    db = InMemoryDatabaseService();
    Services.db = db;
    Services.notifications = InMemoryNotificationService();
  });

  group('ProfileSettingsCard Tests', () {
    testWidgets(
      'renders active profile information and partner role switcher',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(child: ProfileSettingsCard()),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Active Profile'), findsOneWidget);
        expect(
          find.textContaining('Email: husband@example.com'),
          findsOneWidget,
        );
        expect(find.textContaining('Shared Chart ID:'), findsOneWidget);
        expect(find.byKey(const Key('role_segmented_button')), findsOneWidget);
        expect(find.text('Wife / Tracker'), findsOneWidget);
        expect(find.text('Husband / Partner'), findsOneWidget);
      },
    );

    testWidgets('switching partner role updates role in database', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(child: ProfileSettingsCard()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Initial role is husband
      expect(await db.streamUserRole().first, equals('husband'));

      // Tap Wife segment
      await tester.tap(find.text('Wife / Tracker'));
      await tester.pumpAndSettle();

      expect(await db.streamUserRole().first, equals('wife'));

      // Tap Husband segment
      await tester.tap(find.text('Husband / Partner'));
      await tester.pumpAndSettle();

      expect(await db.streamUserRole().first, equals('husband'));
    });
  });
}
