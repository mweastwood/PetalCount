import 'package:flutter_test/flutter_test.dart';
import 'package:petal_count/logic/logic.dart';

void main() {
  late InMemoryDatabaseService db;

  setUp(() {
    db = InMemoryDatabaseService();
  });

  group('DatabaseService Reminder Settings', () {
    test('default chart has reminderEnabled set to true', () async {
      final charts = await db.streamAvailableCharts().first;
      expect(charts, isNotEmpty);
      expect(charts.first['reminderEnabled'], isTrue);

      final isEnabled = await db
          .streamChartReminderEnabled('mock_shared_chart')
          .first;
      expect(isEnabled, isTrue);
    });

    test(
      'updateChartReminderSettings updates reminderEnabled and emits on stream',
      () async {
        await db.updateChartReminderSettings('mock_shared_chart', false);

        final charts = await db.streamAvailableCharts().first;
        expect(charts.first['reminderEnabled'], isFalse);

        final isEnabled = await db
            .streamChartReminderEnabled('mock_shared_chart')
            .first;
        expect(isEnabled, isFalse);

        // Toggle back to true
        await db.updateChartReminderSettings('mock_shared_chart', true);

        final updatedCharts = await db.streamAvailableCharts().first;
        expect(updatedCharts.first['reminderEnabled'], isTrue);

        final isUpdatedEnabled = await db
            .streamChartReminderEnabled('mock_shared_chart')
            .first;
        expect(isUpdatedEnabled, isTrue);
      },
    );

    test(
      'createChart creates a new chart with reminderEnabled: true',
      () async {
        await db.createChart();
        final currentId = db.currentChartId;
        expect(currentId, isNotNull);

        final isEnabled = await db.streamChartReminderEnabled(currentId!).first;
        expect(isEnabled, isTrue);
      },
    );

    test('saveFcmToken and removeFcmToken updates user tokens', () async {
      expect(db.fcmTokens, isEmpty);

      await db.saveFcmToken('token_abc_123');
      expect(db.fcmTokens, contains('token_abc_123'));

      // Duplicate token is not added twice
      await db.saveFcmToken('token_abc_123');
      expect(db.fcmTokens.length, 1);

      await db.saveFcmToken('token_xyz_456');
      expect(db.fcmTokens.length, 2);

      await db.removeFcmToken('token_abc_123');
      expect(db.fcmTokens, ['token_xyz_456']);
    });

    test('updateUserTimezone saves user timezone setting', () async {
      expect(db.userTimezone, isNull);

      await db.updateUserTimezone('America/Los_Angeles');
      expect(db.userTimezone, 'America/Los_Angeles');
    });
  });
}
