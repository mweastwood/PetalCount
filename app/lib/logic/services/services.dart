import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';
import '../app_logger.dart';
import 'database_service.dart';
import 'notification/notification_service.dart';

class Services {
  static late DatabaseService db;
  static late NotificationService notifications;
  static final AppLogger logger = AppLogger();
  static bool get loggerInitialized => true;

  static Future<void> init({
    DatabaseService? dbService,
    NotificationService? notificationService,
  }) async {
    WidgetsFlutterBinding.ensureInitialized();
    try {
      if (dbService != null) {
        db = dbService;
      } else if (Firebase.apps.isNotEmpty) {
        db = FirebaseDatabaseService();
        logger.info(
          'Firebase initialized and FirebaseDatabaseService selected.',
          category: 'init',
        );
      } else {
        db = InMemoryDatabaseService();
        logger.info(
          'Firebase not initialized. Falling back to InMemoryDatabaseService.',
          category: 'init',
        );
      }
    } catch (e, st) {
      db = InMemoryDatabaseService();
      logger.error(
        'Exception initializing services, falling back to InMemoryDatabaseService',
        category: 'init',
        error: e,
        stackTrace: st,
      );
    }

    try {
      if (notificationService != null) {
        notifications = notificationService;
      } else if (Firebase.apps.isNotEmpty) {
        notifications = LocalNotificationService();
      } else {
        notifications = InMemoryNotificationService();
      }
      await notifications.init();
      logger.info('NotificationService initialized.', category: 'init');
    } catch (e, st) {
      notifications = InMemoryNotificationService();
      await notifications.init();
      logger.error(
        'Exception initializing NotificationService, falling back to InMemoryNotificationService',
        category: 'init',
        error: e,
        stackTrace: st,
      );
    }
  }
}
