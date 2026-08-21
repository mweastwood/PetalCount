import 'dart:io' show Platform;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../../utils/date_utils.dart';
import '../services.dart';
import 'notification_service_interface.dart';

class LocalNotificationService implements NotificationService {
  static const int dailyReminderNotificationId = 900;
  static const String notificationChannelId = 'daily_logging_reminders';
  static const String notificationChannelName = 'Daily Logging Reminders';
  static const String notificationChannelDescription =
      'Reminders to log daily Creighton observations by 9:00 PM';

  final FlutterLocalNotificationsPlugin _notificationsPlugin;
  bool _isInitialized = false;
  bool _isReminderScheduled = false;
  DateTime? _scheduledReminderTime;

  LocalNotificationService({
    FlutterLocalNotificationsPlugin? notificationsPlugin,
  }) : _notificationsPlugin =
           notificationsPlugin ?? FlutterLocalNotificationsPlugin();

  @override
  bool get isReminderScheduled => _isReminderScheduled;

  @override
  DateTime? get scheduledReminderTime => _scheduledReminderTime;

  @override
  Future<void> init() async {
    if (_isInitialized) return;

    try {
      tz.initializeTimeZones();
    } catch (e) {
      debugPrint('Warning: Timezone initialization failed: $e');
    }

    if (kIsWeb) {
      _isInitialized = true;
      return;
    }

    try {
      const androidSettings = AndroidInitializationSettings(
        '@mipmap/ic_launcher',
      );
      const darwinSettings = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );
      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: darwinSettings,
        macOS: darwinSettings,
      );

      await _notificationsPlugin.initialize(settings: initSettings);
      _isInitialized = true;
    } catch (e) {
      debugPrint(
        'Warning: FlutterLocalNotificationsPlugin initialize failed: $e',
      );
      _isInitialized = true;
    }
  }

  @override
  Future<bool> requestPermissions() async {
    if (kIsWeb) return true;

    try {
      if (Platform.isAndroid) {
        final androidImplementation = _notificationsPlugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();
        final granted = await androidImplementation
            ?.requestNotificationsPermission();
        return granted ?? false;
      } else if (Platform.isIOS) {
        final iosImplementation = _notificationsPlugin
            .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin
            >();
        final granted = await iosImplementation?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        return granted ?? false;
      } else if (Platform.isMacOS) {
        final macOSImplementation = _notificationsPlugin
            .resolvePlatformSpecificImplementation<
              MacOSFlutterLocalNotificationsPlugin
            >();
        final granted = await macOSImplementation?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        return granted ?? false;
      }
    } catch (e) {
      debugPrint('Warning: requestPermissions failed: $e');
    }
    return false;
  }

  @override
  DateTime calculateNextReminderTime({
    required DateTime now,
    required bool isTodayLogged,
  }) {
    final today9pm = DateTime(now.year, now.month, now.day, 21, 0, 0);
    if (isTodayLogged) {
      final tomorrow = now.addCalendarDays(1);
      return DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 21, 0, 0);
    } else {
      if (now.isBefore(today9pm)) {
        return today9pm;
      } else {
        final tomorrow = now.addCalendarDays(1);
        return DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 21, 0, 0);
      }
    }
  }

  @override
  Future<void> scheduleDailyReminder({required DateTime triggerTime}) async {
    _scheduledReminderTime = triggerTime;
    _isReminderScheduled = true;

    if (kIsWeb) return;

    try {
      final tzLocation = tz.local;
      final scheduledTzDate = tz.TZDateTime.from(triggerTime, tzLocation);

      const androidDetails = AndroidNotificationDetails(
        notificationChannelId,
        notificationChannelName,
        channelDescription: notificationChannelDescription,
        importance: Importance.high,
        priority: Priority.high,
      );
      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );
      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
        macOS: iosDetails,
      );

      await _notificationsPlugin.zonedSchedule(
        id: dailyReminderNotificationId,
        title: 'Daily Observation Reminder',
        body: "Don't forget to log your Creighton observations for today!",
        scheduledDate: scheduledTzDate,
        notificationDetails: notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    } catch (e) {
      debugPrint('Warning: Failed to zonedSchedule notification: $e');
    }
  }

  @override
  Future<void> cancelDailyReminder() async {
    _scheduledReminderTime = null;
    _isReminderScheduled = false;

    if (kIsWeb) return;

    try {
      await _notificationsPlugin.cancel(id: dailyReminderNotificationId);
    } catch (e) {
      debugPrint('Warning: Failed to cancel notification: $e');
    }
  }

  @override
  Future<void> syncReminderSchedule({
    required String? chartId,
    required bool reminderEnabled,
    required bool isTodayLogged,
    DateTime? now,
  }) async {
    if (chartId == null || !reminderEnabled) {
      await cancelDailyReminder();
      return;
    }

    final effectiveNow = now ?? DateTime.now();
    final nextTime = calculateNextReminderTime(
      now: effectiveNow,
      isTodayLogged: isTodayLogged,
    );
    await scheduleDailyReminder(triggerTime: nextTime);
  }

  @override
  Future<void> setupFcmPushNotifications() async {
    if (kIsWeb) return;
    if (Firebase.apps.isEmpty) return;

    try {
      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      final token = await messaging.getToken();
      if (token != null && token.isNotEmpty) {
        await Services.db.saveFcmToken(token);
      }

      messaging.onTokenRefresh.listen((newToken) {
        if (newToken.isNotEmpty) {
          Services.db.saveFcmToken(newToken);
        }
      });

      // Handle notifications received when the app is in the foreground
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        final notification = message.notification;
        if (notification != null) {
          _notificationsPlugin.show(
            id: message.hashCode,
            title: notification.title,
            body: notification.body,
            notificationDetails: const NotificationDetails(
              android: AndroidNotificationDetails(
                notificationChannelId,
                notificationChannelName,
                channelDescription: notificationChannelDescription,
                importance: Importance.high,
                priority: Priority.high,
              ),
              iOS: DarwinNotificationDetails(
                presentAlert: true,
                presentBadge: true,
                presentSound: true,
              ),
            ),
          );
        }
      });
    } catch (e) {
      debugPrint('Warning: setupFcmPushNotifications failed: $e');
    }
  }

  @override
  Future<String?> getFcmToken() async {
    if (kIsWeb) return null;
    if (Firebase.apps.isEmpty) return null;
    try {
      return await FirebaseMessaging.instance.getToken();
    } catch (e) {
      debugPrint('Warning: getFcmToken failed: $e');
      return null;
    }
  }
}
