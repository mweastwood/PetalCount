import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petal_count/logic/services/database/firebase_database_service.dart';

import '../helpers/fake_firebase.dart';

void main() {
  late FakeFirebaseFirestore fakeDb;
  late FakeFirebaseAuth fakeAuth;
  late FakeUser currentUser;
  late FirebaseDatabaseService service;

  setUp(() {
    fakeDb = FakeFirebaseFirestore();
    currentUser = FakeUser(uid: 'user_123', email: 'user@example.com');
    fakeAuth = FakeFirebaseAuth(currentUser: currentUser);
    service = FirebaseDatabaseService(auth: fakeAuth, db: fakeDb);
  });

  // ===========================================================================
  // Group 5: Supplement Formulary & Dose Logging
  // ===========================================================================
  group('Group 5: Supplement Formulary & Dose Logging', () {
    const chartId = 'supp_chart_1';

    setUp(() {
      service.cachedChartId = chartId;
      fakeDb.store['charts/$chartId'] = {'id': chartId};
    });

    test(
      'saveSupplement and deleteSupplement: assert persistence and deletion',
      () async {
        const item = SupplementItem(
          id: 'vitamin_c',
          name: 'Vitamin C',
          quantity: '1 tablet',
          morningDose: 1,
        );

        await service.saveSupplement(item);
        final suppDoc = fakeDb.store['charts/$chartId/supplements/vitamin_c'];
        expect(suppDoc, isNotNull);
        expect(suppDoc!['name'], equals('Vitamin C'));

        await service.deleteSupplement('vitamin_c');
        expect(fakeDb.store['charts/$chartId/supplements/vitamin_c'], isNull);
      },
    );

    test('streamSupplements: streams supplement items in chart', () async {
      fakeDb.store['charts/$chartId/supplements/item1'] = {
        'id': 'item1',
        'name': 'Item 1',
        'quantity': '10mg',
        'morningDose': 1,
      };

      final supplements = await service.streamSupplements().first;
      expect(supplements.length, equals(1));
      expect(supplements.first.name, equals('Item 1'));
    });

    test(
      'logSupplementDose: toggles dose in supplementLogs transaction',
      () async {
        final testDate = DateTime(2026, 9, 14);
        final dateKey = testDate.dateKey;

        await service.logSupplementDose(
          date: testDate,
          supplementId: 'prenatal',
          timeOfDay: SupplementTimeOfDay.morning,
          taken: true,
        );

        final logDoc = fakeDb.store['charts/$chartId/supplementLogs/$dateKey'];
        expect(logDoc, isNotNull);
        final takenDoses = logDoc!['takenDoses'] as Map;
        expect(takenDoses['prenatal'], contains('morning'));

        // Toggle off
        await service.logSupplementDose(
          date: testDate,
          supplementId: 'prenatal',
          timeOfDay: SupplementTimeOfDay.morning,
          taken: false,
        );

        final updatedDoc =
            fakeDb.store['charts/$chartId/supplementLogs/$dateKey'];
        final updatedTaken = updatedDoc!['takenDoses'] as Map;
        expect(updatedTaken['prenatal'] ?? [], isEmpty);
      },
    );

    test(
      'streamDailySupplementLogs: streams daily supplement log map',
      () async {
        final testDate = DateTime(2026, 9, 14);
        final dateKey = testDate.dateKey;
        fakeDb.store['charts/$chartId/supplementLogs/$dateKey'] = {
          'date': dateKey,
          'takenDoses': {
            'iron': ['evening'],
          },
        };

        final logs = await service.streamDailySupplementLogs().first;
        expect(logs.containsKey(dateKey), isTrue);
        expect(
          logs[dateKey]!.isTaken('iron', SupplementTimeOfDay.evening),
          isTrue,
        );
      },
    );
  });
}
