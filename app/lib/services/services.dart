import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';
import 'database_service.dart';

class Services {
  static late final DatabaseService db;

  static Future<void> init() async {
    WidgetsFlutterBinding.ensureInitialized();
    try {
      if (Firebase.apps.isNotEmpty) {
        db = FirebaseDatabaseService();
        debugPrint(
          'Services: Firebase initialized and DatabaseService selected.',
        );
      } else {
        db = InMemoryDatabaseService();
        debugPrint(
          'Services: Firebase not initialized. Falling back to InMemoryDatabaseService.',
        );
      }
    } catch (e) {
      db = InMemoryDatabaseService();
      debugPrint(
        'Services: Exception initializing services: $e. Falling back to InMemoryDatabaseService.',
      );
    }
  }
}
