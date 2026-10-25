// ignore_for_file: subtype_of_sealed_class, depend_on_referenced_packages

import 'package:core/core.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/firebase_core_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petal_count/logic/services/database_service.dart';
import 'package:petal_count/logic/services/notification/notification_service.dart';
import 'package:petal_count/logic/services/services.dart';

// =============================================================================
// Mock / Fake Platform & Service Helpers
// =============================================================================

class MockEmptyFirebasePlatform extends FirebasePlatform {
  MockEmptyFirebasePlatform() : super();

  @override
  List<FirebaseAppPlatform> get apps => [];

  @override
  FirebaseAppPlatform app([String name = defaultFirebaseAppName]) {
    throw FirebaseException(
      plugin: 'core',
      code: 'no-app',
      message: 'No Firebase App "$name" has been created',
    );
  }
}

class MockConfiguredFirebasePlatform extends FirebasePlatform {
  final FirebaseAppPlatform _app;
  bool throwOnApps;
  bool throwOnSubsequentAccess;
  int appsAccessCount = 0;

  MockConfiguredFirebasePlatform({
    FirebaseAppPlatform? app,
    this.throwOnApps = false,
    this.throwOnSubsequentAccess = false,
  }) : _app =
           app ??
           FirebaseAppPlatform(
             defaultFirebaseAppName,
             const FirebaseOptions(
               apiKey: 'mock-api-key',
               appId: 'mock-app-id',
               messagingSenderId: 'mock-sender-id',
               projectId: 'mock-project-id',
             ),
           ),
       super();

  @override
  List<FirebaseAppPlatform> get apps {
    appsAccessCount++;
    if (throwOnApps || (throwOnSubsequentAccess && appsAccessCount > 1)) {
      throw FirebaseException(
        plugin: 'core',
        code: 'channel-error',
        message: 'Platform channels unmocked or failed',
      );
    }
    return [_app];
  }

  @override
  FirebaseAppPlatform app([String name = defaultFirebaseAppName]) {
    if (throwOnApps || throwOnSubsequentAccess) {
      throw FirebaseException(
        plugin: 'core',
        code: 'channel-error',
        message: 'Platform channels unmocked or failed',
      );
    }
    if (name == _app.name) {
      return _app;
    }
    throw FirebaseException(
      plugin: 'core',
      code: 'no-app',
      message: 'No Firebase App "$name" has been created',
    );
  }
}

class CustomTestDatabaseService extends InMemoryDatabaseService {
  final String identifier;
  CustomTestDatabaseService({this.identifier = 'custom-db-1'});
}

class CustomTestNotificationService extends InMemoryNotificationService {
  int initCallCount = 0;

  @override
  Future<void> init() async {
    initCallCount++;
    await super.init();
  }
}

class ThrowingNotificationService extends InMemoryNotificationService {
  @override
  Future<void> init() async {
    throw Exception('Notification initialization failed');
  }
}

// =============================================================================
// Services Unit Tests
// =============================================================================

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    Firebase.delegatePackingProperty = null;
    FirebasePlatform.instance = MockEmptyFirebasePlatform();
    Services.logger.clear();
    Services.db = InMemoryDatabaseService();
    Services.notifications = InMemoryNotificationService();
  });

  tearDown(() {
    Firebase.delegatePackingProperty = null;
    FirebasePlatform.instance = MockEmptyFirebasePlatform();
    Services.logger.clear();
    Services.db = InMemoryDatabaseService();
    Services.notifications = InMemoryNotificationService();
  });

  group('Group 1: Static Properties & Defaults', () {
    test('Services.loggerInitialized and logger property', () {
      expect(Services.loggerInitialized, isTrue);
      expect(Services.logger, isNotNull);

      Services.logger.info('Test log event', category: 'test');
      expect(
        Services.logger.logs.any(
          (e) => e.category == 'test' && e.message == 'Test log event',
        ),
        isTrue,
      );
    });

    test('Initial static state defaults to in-memory services', () {
      expect(Services.db, isA<InMemoryDatabaseService>());
      expect(Services.notifications, isA<InMemoryNotificationService>());
    });
  });

  group('Group 2: Default Initialization', () {
    test(
      'Services.init() without arguments when Firebase is not initialized',
      () async {
        expect(Firebase.apps.isEmpty, isTrue);

        await Services.init();

        expect(Services.db, isA<InMemoryDatabaseService>());
        expect(Services.notifications, isA<InMemoryNotificationService>());
        expect(
          (Services.notifications as InMemoryNotificationService).isInitialized,
          isTrue,
        );
        expect(
          Services.logger.logs.any(
            (log) =>
                log.level == LogLevel.info &&
                log.category == 'init' &&
                log.message ==
                    'Firebase not initialized. Falling back to InMemoryDatabaseService.',
          ),
          isTrue,
        );
        expect(
          Services.logger.logs.any(
            (log) =>
                log.level == LogLevel.info &&
                log.category == 'init' &&
                log.message == 'NotificationService initialized.',
          ),
          isTrue,
        );
      },
    );
  });

  group('Group 3: Custom Dependency Injection', () {
    test(
      'Services.init() with custom dbService and notificationService',
      () async {
        final customDb = CustomTestDatabaseService(identifier: 'custom-db-1');
        final customNotification = CustomTestNotificationService();

        await Services.init(
          dbService: customDb,
          notificationService: customNotification,
        );

        expect(identical(Services.db, customDb), isTrue);
        expect(identical(Services.notifications, customNotification), isTrue);
        expect(customNotification.isInitialized, isTrue);
        expect(customNotification.initCallCount, 1);
        expect(
          Services.logger.logs.any(
            (log) =>
                log.level == LogLevel.info &&
                log.category == 'init' &&
                log.message == 'NotificationService initialized.',
          ),
          isTrue,
        );
      },
    );

    test(
      'Partial injection: dbService only preserves custom db and defaults notifications',
      () async {
        final customDb = CustomTestDatabaseService(
          identifier: 'custom-db-partial',
        );

        await Services.init(dbService: customDb);

        expect(identical(Services.db, customDb), isTrue);
        expect(Services.notifications, isA<InMemoryNotificationService>());
        expect(
          (Services.notifications as InMemoryNotificationService).isInitialized,
          isTrue,
        );
        expect(
          Services.logger.logs.any(
            (log) =>
                log.level == LogLevel.info &&
                log.category == 'init' &&
                log.message == 'NotificationService initialized.',
          ),
          isTrue,
        );
      },
    );

    test(
      'Partial injection: notificationService only preserves custom notifications and defaults db',
      () async {
        final customNotification = CustomTestNotificationService();

        await Services.init(notificationService: customNotification);

        expect(Services.db, isA<InMemoryDatabaseService>());
        expect(identical(Services.notifications, customNotification), isTrue);
        expect(customNotification.isInitialized, isTrue);
        expect(customNotification.initCallCount, 1);
        expect(
          Services.logger.logs.any(
            (log) =>
                log.level == LogLevel.info &&
                log.category == 'init' &&
                log.message ==
                    'Firebase not initialized. Falling back to InMemoryDatabaseService.',
          ),
          isTrue,
        );
        expect(
          Services.logger.logs.any(
            (log) =>
                log.level == LogLevel.info &&
                log.category == 'init' &&
                log.message == 'NotificationService initialized.',
          ),
          isTrue,
        );
      },
    );
  });

  group('Group 4: Error Recovery & Resilience', () {
    test(
      'Database initialization error recovery falls back to InMemoryDatabaseService when platform channel throws during init',
      () async {
        // Configure FirebasePlatform.instance with MockConfiguredFirebasePlatform
        // where Firebase.apps.isNotEmpty is true initially, but platform channel access during init throws
        final platform = MockConfiguredFirebasePlatform(
          throwOnSubsequentAccess: true,
        );
        Firebase.delegatePackingProperty = null;
        FirebasePlatform.instance = platform;

        expect(Firebase.apps.isNotEmpty, isTrue);

        await Services.init();

        expect(Services.db, isA<InMemoryDatabaseService>());
        expect(
          Services.logger.logs.any(
            (log) =>
                log.level == LogLevel.error &&
                log.category == 'init' &&
                log.message ==
                    'Exception initializing services, falling back to InMemoryDatabaseService',
          ),
          isTrue,
        );
      },
    );

    test(
      'Database initialization error recovery when platform throws on direct apps query',
      () async {
        Firebase.delegatePackingProperty = null;
        FirebasePlatform.instance = MockConfiguredFirebasePlatform(
          throwOnApps: true,
        );

        await Services.init();

        expect(Services.db, isA<InMemoryDatabaseService>());
        expect(
          Services.logger.logs.any(
            (log) =>
                log.level == LogLevel.error &&
                log.category == 'init' &&
                log.message ==
                    'Exception initializing services, falling back to InMemoryDatabaseService',
          ),
          isTrue,
        );
      },
    );

    test(
      'Notification initialization error recovery falls back to InMemoryNotificationService',
      () async {
        final throwingNotification = ThrowingNotificationService();

        await Services.init(notificationService: throwingNotification);

        expect(Services.notifications, isA<InMemoryNotificationService>());
        expect(
          identical(Services.notifications, throwingNotification),
          isFalse,
        );
        expect(
          (Services.notifications as InMemoryNotificationService).isInitialized,
          isTrue,
        );
        expect(
          Services.logger.logs.any(
            (log) =>
                log.level == LogLevel.error &&
                log.category == 'init' &&
                log.message ==
                    'Exception initializing NotificationService, falling back to InMemoryNotificationService',
          ),
          isTrue,
        );
      },
    );
  });

  group('Group 5: Configured Firebase Initialization Branch', () {
    test(
      'Services.init() with Firebase configured selects FirebaseDatabaseService and LocalNotificationService',
      () async {
        Firebase.delegatePackingProperty = null;
        FirebasePlatform.instance = MockConfiguredFirebasePlatform();
        expect(Firebase.apps.isNotEmpty, isTrue);

        await Services.init();

        expect(Services.db, isA<FirebaseDatabaseService>());
        expect(Services.notifications, isA<LocalNotificationService>());
        expect(
          Services.logger.logs.any(
            (log) =>
                log.level == LogLevel.info &&
                log.category == 'init' &&
                log.message ==
                    'Firebase initialized and FirebaseDatabaseService selected.',
          ),
          isTrue,
        );
        expect(
          Services.logger.logs.any(
            (log) =>
                log.level == LogLevel.info &&
                log.category == 'init' &&
                log.message == 'NotificationService initialized.',
          ),
          isTrue,
        );
      },
    );
  });
}
