import 'package:flutter_test/flutter_test.dart';
import 'package:petal_count/logic/logic.dart';

void main() {
  late InMemoryDatabaseService db;
  late InMemoryNotificationService notifications;

  setUp(() {
    db = InMemoryDatabaseService();
    notifications = InMemoryNotificationService();
    Services.db = db;
    Services.notifications = notifications;
  });

  group('CreightonLogic Fertile Pattern Detection', () {
    test('detects fertile mucus patterns vs infertile BIP and bleeding', () {
      final date = DateTime(2026, 8, 20);

      // Bleeding entry is not fertile mucus pattern
      final bleedingObs = Observation(
        id: 'obs1',
        timestamp: date,
        sensation: Sensation.dry,
        stretch: Stretch.none,
        colors: [],
        consistencies: [],
        bleeding: Bleeding.heavy,
        bleedingColor: 'R',
        painLevel: 0,
        painTypes: [],
        comment: '',
        userId: 'wife_uid',
      );
      final bleedingEntry = CreightonLogic.resolveDailyEntry(
        date: date,
        observations: [bleedingObs],
      );
      expect(
        CreightonLogic.isFertileMucusPattern(
          entry: bleedingEntry,
          bipCodes: const ['6C'],
        ),
        isFalse,
      );

      // Non-BIP mucus observation (fertile)
      final fertileObs = Observation(
        id: 'obs2',
        timestamp: date,
        sensation: Sensation.shiny,
        stretch: Stretch.stretchy,
        colors: [MucusColor.clear],
        consistencies: [],
        bleeding: Bleeding.none,
        bleedingColor: '',
        painLevel: 0,
        painTypes: [],
        comment: '',
        userId: 'wife_uid',
      );
      final fertileEntry = CreightonLogic.resolveDailyEntry(
        date: date,
        observations: [fertileObs],
      );
      expect(
        CreightonLogic.isFertileMucusPattern(
          entry: fertileEntry,
          bipCodes: const ['6C'],
        ),
        isTrue,
      );

      // BIP mucus observation (infertile when BIP code matches)
      final bipObs = Observation(
        id: 'obs3',
        timestamp: date,
        sensation: Sensation.damp,
        stretch: Stretch.sticky,
        colors: [MucusColor.cloudy],
        consistencies: [],
        bleeding: Bleeding.none,
        bleedingColor: '',
        painLevel: 0,
        painTypes: [],
        comment: '',
        userId: 'wife_uid',
      );
      final bipEntry = CreightonLogic.resolveDailyEntry(
        date: date,
        observations: [bipObs],
      );
      // When 6C is configured as BIP
      final recalculated = CreightonLogic.recalculateCycle(
        entries: [bipEntry],
        bipCodes: const ['6C'],
      );
      expect(
        CreightonLogic.isFertileMucusPattern(
          entry: recalculated[date.dateKey]!,
          bipCodes: const ['6C'],
        ),
        isFalse,
      );
    });
  });

  group('DatabaseService Role & Notification Preferences', () {
    test('updates and streams user role', () async {
      expect(await db.streamUserRole().first, 'husband');

      await db.updateUserRole('wife');
      expect(await db.streamUserRole().first, 'wife');

      await db.updateUserRole('husband');
      expect(await db.streamUserRole().first, 'husband');
    });

    test('updates and streams notification preferences', () async {
      const chartId = 'mock_shared_chart';
      final initialPrefs = await db
          .streamNotificationPreferences(chartId)
          .first;
      expect(initialPrefs.fertilePatternAlerts, isTrue);
      expect(initialPrefs.partnerSupportReminders, isTrue);
      expect(initialPrefs.dailyLoggingReminder, isTrue);

      final updatedPrefs = initialPrefs.copyWith(
        fertilePatternAlerts: false,
        partnerSupportReminders: false,
      );
      await db.updateNotificationPreferences(chartId, updatedPrefs);

      final newPrefs = await db.streamNotificationPreferences(chartId).first;
      expect(newPrefs.fertilePatternAlerts, isFalse);
      expect(newPrefs.partnerSupportReminders, isFalse);
      expect(newPrefs.dailyLoggingReminder, isTrue);
    });

    test(
      'saveObservation triggers fertile pattern & kindness notifications',
      () async {
        expect(notifications.dispatchedNotifications, isEmpty);

        // Save a fertile observation
        final date = DateTime(2026, 6, 14);
        await db.saveObservation(
          date: date,
          sensation: Sensation.wet,
          stretch: Stretch.stretchy,
          colors: [MucusColor.clear],
          consistencies: [Consistency.lubricative],
          bleeding: Bleeding.none,
          bleedingColor: '',
          painLevel: 0,
          painTypes: [],
          comment: 'Fertile mucus test',
        );

        // Verify that notification service received fertile pattern & kindness alerts
        expect(notifications.notificationCount, greaterThanOrEqualTo(1));
        expect(
          notifications.dispatchedNotifications.any(
            (n) => n['body'].toString().contains(
              'Fertile mucus pattern recorded today',
            ),
          ),
          isTrue,
        );
        expect(
          notifications.dispatchedNotifications.any(
            (n) => n['body'].toString().contains('Reminder to be kind'),
          ),
          isTrue,
        );
      },
    );

    test(
      'NotificationService deduplicates alerts sent on the same day',
      () async {
        expect(notifications.notificationCount, 0);

        final now = DateTime(2026, 8, 21);
        await notifications.notifyFertilePattern(
          role: UserRole.husband,
          now: now,
        );
        expect(notifications.notificationCount, 1);

        // Calling again on the same day without force should deduplicate
        await notifications.notifyFertilePattern(
          role: UserRole.husband,
          now: now,
        );
        expect(notifications.notificationCount, 1);

        // Calling with force=true bypasses deduplication
        await notifications.notifyFertilePattern(
          role: UserRole.husband,
          now: now,
          force: true,
        );
        expect(notifications.notificationCount, 2);

        // Kindness alerts deduplicate per day
        await notifications.notifyKindnessSupport(
          role: UserRole.husband,
          now: now,
        );
        expect(notifications.notificationCount, 3);
        await notifications.notifyKindnessSupport(
          role: UserRole.husband,
          now: now,
        );
        expect(notifications.notificationCount, 3);
      },
    );
  });
}
