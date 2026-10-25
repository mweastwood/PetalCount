import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petal_count/logic/services/database/database_helpers.dart';
import 'package:petal_count/logic/services/database/firebase_database_helpers.dart';
import 'package:petal_count/logic/services/notification/in_memory_notification_service.dart';
import 'package:petal_count/logic/services/services.dart';

class _DuckTypedError {
  final dynamic code;
  final String message;

  _DuckTypedError({this.code, this.message = 'generic error'});

  @override
  String toString() => message;
}

class _ThrowingCodeError {
  final String message;

  _ThrowingCodeError(this.message);

  String get code => throw StateError('code getter failed');

  @override
  String toString() => message;
}

class _PeakOnlyDailyEntry extends Fake implements DailyEntry {
  @override
  final DateTime date = DateTime(2026, 6, 15);

  @override
  final bool hasBleeding = false;

  @override
  final bool hasMucus = false;

  @override
  final bool isPeakType = false;

  @override
  final List<Observation> observations = const [];

  @override
  final StampType stampType = StampType.greenBaby;

  @override
  final String? peakDayLabel = null;

  @override
  final bool isPeakDay = true;
}

void main() {
  group('DatabaseHelpers.parseChartNotificationPreferences', () {
    test('returns default NotificationPreferences when chartData is null', () {
      final prefs = DatabaseHelpers.parseChartNotificationPreferences(null);

      expect(prefs, const NotificationPreferences());
      expect(prefs.fertilePatternAlerts, isTrue);
      expect(prefs.partnerSupportReminders, isTrue);
      expect(prefs.dailyLoggingReminder, isTrue);
      expect(prefs.breastSelfExamReminder, isTrue);
    });

    test(
      'returns default NotificationPreferences when chartData is empty map',
      () {
        final prefs = DatabaseHelpers.parseChartNotificationPreferences({});

        expect(prefs, const NotificationPreferences());
        expect(prefs.dailyLoggingReminder, isTrue);
      },
    );

    test(
      'falls back to legacy reminderEnabled when notificationPreferences is absent',
      () {
        final disabledPrefs = DatabaseHelpers.parseChartNotificationPreferences(
          {'reminderEnabled': false},
        );
        expect(disabledPrefs.dailyLoggingReminder, isFalse);
        expect(disabledPrefs.fertilePatternAlerts, isTrue);
        expect(disabledPrefs.partnerSupportReminders, isTrue);
        expect(disabledPrefs.breastSelfExamReminder, isTrue);

        final enabledPrefs = DatabaseHelpers.parseChartNotificationPreferences({
          'reminderEnabled': true,
        });
        expect(enabledPrefs.dailyLoggingReminder, isTrue);
      },
    );

    test(
      'explicit notificationPreferences map takes precedence over legacy reminderEnabled',
      () {
        final prefs = DatabaseHelpers.parseChartNotificationPreferences({
          'reminderEnabled': true,
          'notificationPreferences': {
            'fertilePatternAlerts': false,
            'partnerSupportReminders': false,
            'dailyLoggingReminder': false,
            'breastSelfExamReminder': false,
          },
        });

        expect(prefs.fertilePatternAlerts, isFalse);
        expect(prefs.partnerSupportReminders, isFalse);
        expect(prefs.dailyLoggingReminder, isFalse);
        expect(prefs.breastSelfExamReminder, isFalse);
      },
    );
  });

  group('DatabaseHelpers.dispatchLocalObservationNotifications', () {
    late InMemoryNotificationService notificationService;
    final testDate = DateTime(2026, 6, 15);

    DailyEntry buildFertileMucusEntry({String? peakDayLabel}) {
      final obs = Observation(
        id: 'obs_fertile',
        timestamp: testDate,
        sensation: Sensation.wet,
        stretch: Stretch.stretchy,
        colors: const [MucusColor.clear],
        consistencies: const [Consistency.lubricative],
        bleeding: Bleeding.none,
        userId: 'wife_uid',
        userRole: UserRole.wife.code,
      );
      return DailyEntry(
        date: testDate,
        resolvedVdrsCode: '10WLK',
        stampType: StampType.whiteBaby,
        observations: [obs],
        painLevel: 0.0,
        painTypes: const [],
        comments: '',
        peakDayLabel: peakDayLabel,
      );
    }

    DailyEntry buildDryEntry({
      String? peakDayLabel,
      StampType stampType = StampType.green,
    }) {
      final obs = Observation(
        id: 'obs_dry',
        timestamp: testDate,
        sensation: Sensation.dry,
        stretch: Stretch.none,
        colors: const [],
        consistencies: const [],
        bleeding: Bleeding.none,
        userId: 'wife_uid',
        userRole: UserRole.wife.code,
      );
      return DailyEntry(
        date: testDate,
        resolvedVdrsCode: '0',
        stampType: stampType,
        observations: [obs],
        painLevel: 0.0,
        painTypes: const [],
        comments: '',
        peakDayLabel: peakDayLabel,
      );
    }

    setUp(() {
      notificationService = InMemoryNotificationService();
      Services.notifications = notificationService;
    });

    test(
      'fertile mucus day dispatches fertile pattern and kindness support when enabled',
      () async {
        final entry = buildFertileMucusEntry();

        await DatabaseHelpers.dispatchLocalObservationNotifications(
          resolvedDaily: entry,
          bipCodes: const ['6C'],
          userRole: UserRole.wife,
          preferences: const NotificationPreferences(
            fertilePatternAlerts: true,
            partnerSupportReminders: true,
          ),
        );

        final ids = notificationService.dispatchedNotifications
            .map((n) => n['id'] as int)
            .toList();
        expect(ids, [
          InMemoryNotificationService.fertilePatternNotificationId,
          InMemoryNotificationService.kindnessSupportNotificationId,
        ]);
      },
    );

    test(
      'fertile mucus day respects disabled fertilePatternAlerts and partnerSupportReminders',
      () async {
        final entry = buildFertileMucusEntry();

        await DatabaseHelpers.dispatchLocalObservationNotifications(
          resolvedDaily: entry,
          bipCodes: const ['6C'],
          userRole: UserRole.wife,
          preferences: const NotificationPreferences(
            fertilePatternAlerts: false,
            partnerSupportReminders: false,
          ),
        );

        expect(notificationService.dispatchedNotifications, isEmpty);
      },
    );

    test(
      'peak day with peakDayLabel dispatches fertile, peak, and kindness notifications when enabled',
      () async {
        final entry = buildFertileMucusEntry(peakDayLabel: 'P');

        await DatabaseHelpers.dispatchLocalObservationNotifications(
          resolvedDaily: entry,
          bipCodes: const ['6C'],
          userRole: UserRole.husband,
          preferences: const NotificationPreferences(
            fertilePatternAlerts: true,
            partnerSupportReminders: true,
          ),
        );

        final ids = notificationService.dispatchedNotifications
            .map((n) => n['id'] as int)
            .toList();
        expect(ids, [
          InMemoryNotificationService.fertilePatternNotificationId,
          InMemoryNotificationService.peakDayNotificationId,
          InMemoryNotificationService.kindnessSupportNotificationId,
        ]);
      },
    );

    test(
      'post-peak dry day with peakDayLabel dispatches peak and kindness notifications according to preferences',
      () async {
        final entry = buildDryEntry(
          peakDayLabel: '1',
          stampType: StampType.greenBaby,
        );

        await DatabaseHelpers.dispatchLocalObservationNotifications(
          resolvedDaily: entry,
          bipCodes: const ['6C'],
          userRole: UserRole.wife,
          preferences: const NotificationPreferences(
            fertilePatternAlerts: true,
            partnerSupportReminders: false,
          ),
        );

        expect(
          notificationService.dispatchedNotifications
              .map((n) => n['id'])
              .toList(),
          [InMemoryNotificationService.peakDayNotificationId],
        );

        notificationService.dispatchedNotifications.clear();
        notificationService.sentNotificationDeduplicationKeys.clear();

        await DatabaseHelpers.dispatchLocalObservationNotifications(
          resolvedDaily: entry,
          bipCodes: const ['6C'],
          userRole: UserRole.wife,
          preferences: const NotificationPreferences(
            fertilePatternAlerts: false,
            partnerSupportReminders: true,
          ),
        );

        expect(
          notificationService.dispatchedNotifications
              .map((n) => n['id'])
              .toList(),
          [InMemoryNotificationService.kindnessSupportNotificationId],
        );
      },
    );

    test(
      'entry with isPeakDay true and null peakDayLabel still triggers partner support reminder when enabled',
      () async {
        final entry = _PeakOnlyDailyEntry();

        await DatabaseHelpers.dispatchLocalObservationNotifications(
          resolvedDaily: entry,
          bipCodes: const ['6C'],
          userRole: UserRole.husband,
          preferences: const NotificationPreferences(
            fertilePatternAlerts: true,
            partnerSupportReminders: true,
          ),
        );

        expect(
          notificationService.dispatchedNotifications
              .map((n) => n['id'])
              .toList(),
          [InMemoryNotificationService.kindnessSupportNotificationId],
        );
      },
    );

    test(
      'non-fertile dry day dispatches no notifications even when all preferences are enabled',
      () async {
        final entry = buildDryEntry();

        await DatabaseHelpers.dispatchLocalObservationNotifications(
          resolvedDaily: entry,
          bipCodes: const ['6C'],
          userRole: UserRole.wife,
          preferences: const NotificationPreferences(
            fertilePatternAlerts: true,
            partnerSupportReminders: true,
          ),
        );

        expect(notificationService.dispatchedNotifications, isEmpty);
      },
    );
  });

  group('FirebaseDatabaseHelpers.isAccessLostError', () {
    test('matches FirebaseException with permission-denied or not-found', () {
      expect(
        FirebaseDatabaseHelpers.isAccessLostError(
          FirebaseException(
            plugin: 'cloud_firestore',
            code: 'permission-denied',
          ),
        ),
        isTrue,
      );
      expect(
        FirebaseDatabaseHelpers.isAccessLostError(
          FirebaseException(
            plugin: 'cloud_firestore',
            code: 'PERMISSION_DENIED',
          ),
        ),
        isTrue,
      );
      expect(
        FirebaseDatabaseHelpers.isAccessLostError(
          FirebaseException(plugin: 'cloud_firestore', code: 'not-found'),
        ),
        isTrue,
      );
      expect(
        FirebaseDatabaseHelpers.isAccessLostError(
          FirebaseException(plugin: 'cloud_firestore', code: 'unavailable'),
        ),
        isFalse,
      );
    });

    test(
      'matches duck-typed objects with String .code property like permission_denied or not-found',
      () {
        expect(
          FirebaseDatabaseHelpers.isAccessLostError(
            _DuckTypedError(code: 'permission_denied'),
          ),
          isTrue,
        );
        expect(
          FirebaseDatabaseHelpers.isAccessLostError(
            _DuckTypedError(code: 'not-found'),
          ),
          isTrue,
        );
        expect(
          FirebaseDatabaseHelpers.isAccessLostError(
            _DuckTypedError(code: 'NOT_FOUND'),
          ),
          isTrue,
        );
        expect(
          FirebaseDatabaseHelpers.isAccessLostError(
            _DuckTypedError(code: 'deadline-exceeded'),
          ),
          isFalse,
        );
      },
    );

    test(
      'handles objects whose .code getter throws or returns non-String and falls back to toString()',
      () {
        expect(
          FirebaseDatabaseHelpers.isAccessLostError(
            _DuckTypedError(code: 403, message: 'Error: permission_denied'),
          ),
          isTrue,
        );
        expect(
          FirebaseDatabaseHelpers.isAccessLostError(
            _DuckTypedError(code: 500, message: 'Internal server error'),
          ),
          isFalse,
        );
        expect(
          FirebaseDatabaseHelpers.isAccessLostError(
            _ThrowingCodeError('Firestore error: document not-found'),
          ),
          isTrue,
        );
        expect(
          FirebaseDatabaseHelpers.isAccessLostError(
            _ThrowingCodeError('Transient network timeout'),
          ),
          isFalse,
        );
      },
    );

    test(
      'falls back to toString() matching for plain exceptions and strings',
      () {
        expect(
          FirebaseDatabaseHelpers.isAccessLostError(
            Exception('Caller does not have permission-denied access'),
          ),
          isTrue,
        );
        expect(
          FirebaseDatabaseHelpers.isAccessLostError(
            Exception('Resource not_found in database'),
          ),
          isTrue,
        );
        expect(
          FirebaseDatabaseHelpers.isAccessLostError(
            Exception('Network connection lost'),
          ),
          isFalse,
        );
      },
    );
  });
}
