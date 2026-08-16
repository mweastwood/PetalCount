import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';
import '../app_logger.dart';
import 'database_service.dart';

class Services {
  static late DatabaseService db;
  static final AppLogger logger = AppLogger();
  static bool get loggerInitialized => true;

  static Future<void> init() async {
    WidgetsFlutterBinding.ensureInitialized();
    try {
      if (Firebase.apps.isNotEmpty) {
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
  }
}
