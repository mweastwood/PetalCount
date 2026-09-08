import 'package:flutter_test/flutter_test.dart';
import 'package:petal_count/logic/models/notification_preferences.dart';
import 'package:petal_count/logic/models/user_role.dart';
import 'package:petal_count/logic/services/database/firebase_database_service.dart';

void main() {
  group('FirebaseDatabaseService.resolveNotificationContext', () {
    const testUid = 'user_123';
    const testChartId = 'chart_456';

    test(
      'returns immediately from memory when both role and preferences are cached (0 network calls)',
      () async {
        int userCalls = 0;
        int chartCalls = 0;

        const cachedPrefs = NotificationPreferences(
          fertilePatternAlerts: false,
          partnerSupportReminders: true,
        );

        final result = await FirebaseDatabaseService.resolveNotificationContext(
          uid: testUid,
          chartId: testChartId,
          cachedRole: 'husband',
          cachedPreferences: cachedPrefs,
          getUserData: (uid) async {
            userCalls++;
            return {'role': 'wife'};
          },
          getChartData: (chartId) async {
            chartCalls++;
            return {};
          },
        );

        expect(userCalls, 0);
        expect(chartCalls, 0);
        expect(result.userRole, UserRole.husband);
        expect(result.preferences.fertilePatternAlerts, isFalse);
        expect(result.roleToCache, 'husband');
        expect(result.preferencesToCache, cachedPrefs);
      },
    );

    test('only fetches chart preferences when role is cached', () async {
      int userCalls = 0;
      int chartCalls = 0;

      final result = await FirebaseDatabaseService.resolveNotificationContext(
        uid: testUid,
        chartId: testChartId,
        cachedRole: 'wife',
        cachedPreferences: null,
        getUserData: (uid) async {
          userCalls++;
          return {'role': 'husband'};
        },
        getChartData: (chartId) async {
          chartCalls++;
          return {
            'notificationPreferences': {
              'fertilePatternAlerts': false,
              'partnerSupportReminders': false,
            },
          };
        },
      );

      expect(userCalls, 0);
      expect(chartCalls, 1);
      expect(result.userRole, UserRole.wife);
      expect(result.preferences.fertilePatternAlerts, isFalse);
      expect(result.preferences.partnerSupportReminders, isFalse);
      expect(result.roleToCache, 'wife');
    });

    test('only fetches user role when preferences are cached', () async {
      int userCalls = 0;
      int chartCalls = 0;

      const cachedPrefs = NotificationPreferences(
        fertilePatternAlerts: true,
        partnerSupportReminders: false,
      );

      final result = await FirebaseDatabaseService.resolveNotificationContext(
        uid: testUid,
        chartId: testChartId,
        cachedRole: null,
        cachedPreferences: cachedPrefs,
        getUserData: (uid) async {
          userCalls++;
          return {'role': 'husband'};
        },
        getChartData: (chartId) async {
          chartCalls++;
          return {};
        },
      );

      expect(userCalls, 1);
      expect(chartCalls, 0);
      expect(result.userRole, UserRole.husband);
      expect(result.preferences, cachedPrefs);
      expect(result.roleToCache, 'husband');
    });

    test(
      'fetches both in parallel when neither is cached and populates cache',
      () async {
        int userCalls = 0;
        int chartCalls = 0;

        final result = await FirebaseDatabaseService.resolveNotificationContext(
          uid: testUid,
          chartId: testChartId,
          cachedRole: null,
          cachedPreferences: null,
          getUserData: (uid) async {
            userCalls++;
            return {'role': 'husband'};
          },
          getChartData: (chartId) async {
            chartCalls++;
            return {
              'notificationPreferences': {
                'fertilePatternAlerts': true,
                'partnerSupportReminders': false,
              },
            };
          },
        );

        expect(userCalls, 1);
        expect(chartCalls, 1);
        expect(result.userRole, UserRole.husband);
        expect(result.preferences.fertilePatternAlerts, isTrue);
        expect(result.preferences.partnerSupportReminders, isFalse);
        expect(result.roleToCache, 'husband');
      },
    );

    test('handles null documents and defaults safely', () async {
      final result = await FirebaseDatabaseService.resolveNotificationContext(
        uid: testUid,
        chartId: testChartId,
        cachedRole: null,
        cachedPreferences: null,
        getUserData: (uid) async => null,
        getChartData: (chartId) async => null,
      );

      expect(result.userRole, UserRole.wife);
      expect(result.preferences.fertilePatternAlerts, isTrue);
      expect(result.preferences.partnerSupportReminders, isTrue);
      expect(result.roleToCache, 'wife');
    });

    test(
      'handles fallback to reminderEnabled in chart document when notificationPreferences map is absent',
      () async {
        final result = await FirebaseDatabaseService.resolveNotificationContext(
          uid: testUid,
          chartId: testChartId,
          cachedRole: 'wife',
          cachedPreferences: null,
          getUserData: (uid) async => {'role': 'wife'},
          getChartData: (chartId) async => {'reminderEnabled': false},
        );

        expect(result.userRole, UserRole.wife);
        expect(result.preferences.dailyLoggingReminder, isFalse);
      },
    );
  });
}
