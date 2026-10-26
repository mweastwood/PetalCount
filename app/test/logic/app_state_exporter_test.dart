// ignore_for_file: subtype_of_sealed_class, prefer_initializing_formals

import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:core/core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petal_count/logic/app_state_exporter.dart';
import 'package:petal_count/logic/services/database/firebase_database_service.dart';
import 'package:petal_count/logic/services/database/in_memory_database_service.dart';

class _FakeUser extends Fake implements User {
  @override
  final String uid;
  @override
  final String? email;
  @override
  bool get isAnonymous => false;

  _FakeUser({required this.uid, this.email});
}

class _FakeFirebaseAuth extends Fake implements FirebaseAuth {
  final User? _currentUser;
  final StreamController<User?> _authController =
      StreamController<User?>.broadcast();

  _FakeFirebaseAuth({User? currentUser}) : _currentUser = currentUser;

  @override
  User? get currentUser => _currentUser;

  @override
  Stream<User?> authStateChanges() => _authController.stream;
}

class _FakeFirebaseFirestore extends Fake implements FirebaseFirestore {
  final Map<String, Map<String, dynamic>> store = {};
  final Map<String, Object> getDocErrors = {};

  @override
  CollectionReference<Map<String, dynamic>> collection(String collectionPath) {
    return _FakeCollectionReference(this, collectionPath);
  }
}

class _FakeQueryFilter {
  final String field;
  final dynamic isEqualTo;
  final dynamic arrayContains;

  _FakeQueryFilter({required this.field, this.isEqualTo, this.arrayContains});

  bool matches(Map<String, dynamic> data) {
    if (isEqualTo != null && data[field] != isEqualTo) {
      return false;
    }
    if (arrayContains != null) {
      final val = data[field];
      if (val is! List || !val.contains(arrayContains)) {
        return false;
      }
    }
    return true;
  }
}

class _FakeQuery extends Fake implements Query<Map<String, dynamic>> {
  final _FakeFirebaseFirestore firestoreInstance;
  final String collectionPath;
  final List<_FakeQueryFilter> filters;

  _FakeQuery(
    this.firestoreInstance,
    this.collectionPath, {
    List<_FakeQueryFilter>? filters,
  }) : filters = filters ?? [];

  @override
  Query<Map<String, dynamic>> where(
    Object field, {
    Object? isEqualTo,
    Object? isNotEqualTo,
    Object? isLessThan,
    Object? isLessThanOrEqualTo,
    Object? isGreaterThan,
    Object? isGreaterThanOrEqualTo,
    Object? arrayContains,
    Iterable<Object?>? arrayContainsAny,
    Iterable<Object?>? whereIn,
    Iterable<Object?>? whereNotIn,
    bool? isNull,
  }) {
    return _FakeQuery(
      firestoreInstance,
      collectionPath,
      filters: [
        ...filters,
        _FakeQueryFilter(
          field: field.toString(),
          isEqualTo: isEqualTo,
          arrayContains: arrayContains,
        ),
      ],
    );
  }

  @override
  Future<QuerySnapshot<Map<String, dynamic>>> get([GetOptions? options]) async {
    final prefix = '$collectionPath/';
    final docs = <QueryDocumentSnapshot<Map<String, dynamic>>>[];
    for (final entry in firestoreInstance.store.entries) {
      if (entry.key.startsWith(prefix)) {
        final remainder = entry.key.substring(prefix.length);
        if (!remainder.contains('/')) {
          final data = Map<String, dynamic>.from(entry.value);
          if (filters.every((f) => f.matches(data))) {
            docs.add(
              _FakeQueryDocumentSnapshot(
                id: remainder,
                data: data,
                reference: _FakeDocumentReference(firestoreInstance, entry.key),
              ),
            );
          }
        }
      }
    }
    return _FakeQuerySnapshot(docs);
  }
}

class _FakeCollectionReference extends _FakeQuery
    implements CollectionReference<Map<String, dynamic>> {
  @override
  final String path;

  _FakeCollectionReference(_FakeFirebaseFirestore firestoreInstance, this.path)
    : super(firestoreInstance, path);

  @override
  DocumentReference<Map<String, dynamic>> doc([String? documentPath]) {
    return _FakeDocumentReference(firestoreInstance, '$path/$documentPath');
  }
}

class _FakeDocumentReference extends Fake
    implements DocumentReference<Map<String, dynamic>> {
  final _FakeFirebaseFirestore firestoreInstance;
  @override
  final String path;

  _FakeDocumentReference(this.firestoreInstance, this.path);

  @override
  String get id => path.split('/').last;

  @override
  CollectionReference<Map<String, dynamic>> collection(String collectionPath) {
    return _FakeCollectionReference(firestoreInstance, '$path/$collectionPath');
  }

  @override
  Future<DocumentSnapshot<Map<String, dynamic>>> get([
    GetOptions? options,
  ]) async {
    if (firestoreInstance.getDocErrors.containsKey(path)) {
      throw firestoreInstance.getDocErrors[path]!;
    }
    final data = firestoreInstance.store[path];
    return _FakeDocumentSnapshot(
      id: id,
      data: data != null ? Map<String, dynamic>.from(data) : null,
      reference: this,
    );
  }
}

class _FakeDocumentSnapshot extends Fake
    implements DocumentSnapshot<Map<String, dynamic>> {
  @override
  final String id;
  final Map<String, dynamic>? _data;
  @override
  final DocumentReference<Map<String, dynamic>> reference;

  _FakeDocumentSnapshot({
    required this.id,
    required Map<String, dynamic>? data,
    required this.reference,
  }) : _data = data;

  @override
  bool get exists => _data != null;

  @override
  Map<String, dynamic>? data() => _data;
}

class _FakeQueryDocumentSnapshot extends _FakeDocumentSnapshot
    implements QueryDocumentSnapshot<Map<String, dynamic>> {
  _FakeQueryDocumentSnapshot({
    required super.id,
    required Map<String, dynamic> super.data,
    required super.reference,
  });

  @override
  bool get exists => true;

  @override
  Map<String, dynamic> data() => super.data()!;
}

class _FakeQuerySnapshot extends Fake
    implements QuerySnapshot<Map<String, dynamic>> {
  @override
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> docs;

  _FakeQuerySnapshot(this.docs);
}

void main() {
  group('AppStateExporter Unit & Widget Tests', () {
    late InMemoryDatabaseService mockDb;
    late AppLogger mockLogger;
    late AppStateExporter exporter;

    setUp(() {
      mockDb = InMemoryDatabaseService();
      mockLogger = AppLogger(maxCapacity: 100);
      exporter = AppStateExporter(db: mockDb, logger: mockLogger);
    });

    test('maskEmail obfuscates email addresses correctly', () {
      expect(
        AppStateExporter.maskEmail('test@example.com'),
        't***t@example.com',
      );
      expect(AppStateExporter.maskEmail('ab@example.com'), 'a***@example.com');
      expect(AppStateExporter.maskEmail('a@example.com'), 'a***@example.com');
      expect(AppStateExporter.maskEmail('@example.com'), '***@example.com');
      expect(AppStateExporter.maskEmail('no-at-sign'), '***');
    });

    test('maskPii obfuscates embedded emails in freeform strings', () {
      const text =
          'User john.doe@domain.org created chart with spouse jane.doe@domain.org';
      final masked = AppStateExporter.maskPii(text);
      expect(masked, contains('j***e@domain.org'));
      expect(masked, contains('j***e@domain.org'));
      expect(masked, isNot(contains('john.doe@domain.org')));
      expect(masked, isNot(contains('jane.doe@domain.org')));
    });

    test(
      'sanitizeForJson converts complex Dart and Firestore types to primitives',
      () {
        final now = DateTime.utc(2026, 8, 16, 10, 30);
        final timestamp = Timestamp.fromDate(now);

        final input = {
          'dateTime': now,
          'timestamp': timestamp,
          'duration': const Duration(seconds: 45),
          'geoPoint': const GeoPoint(37.7749, -122.4194),
          'enumVal': LogLevel.warning,
          'nestedList': [
            now,
            LogLevel.error,
            {'email': 'secret@example.com'},
          ],
        };

        final sanitized =
            exporter.sanitizeForJson(input, sanitizePii: true)
                as Map<String, dynamic>;

        expect(sanitized['dateTime'], '2026-08-16T10:30:00.000Z');
        expect(sanitized['timestamp'], '2026-08-16T10:30:00.000Z');
        expect(sanitized['duration'], 45000);
        expect(sanitized['geoPoint'], {
          'latitude': 37.7749,
          'longitude': -122.4194,
        });
        expect(sanitized['enumVal'], 'warning');
        final list = sanitized['nestedList'] as List;
        expect(list[0], '2026-08-16T10:30:00.000Z');
        expect(list[1], 'error');
        expect((list[2] as Map)['email'], 's***t@example.com');
      },
    );

    test(
      'sanitizeForJson handles map PII sanitization edge cases correctly',
      () {
        // 1. Non-string keys in maps
        final nonStringKeyMap = {42: 'number_key', true: 'bool_key'};
        final sanitizedNonString =
            exporter.sanitizeForJson(nonStringKeyMap) as Map<String, dynamic>;
        expect(sanitizedNonString['42'], 'number_key');
        expect(sanitizedNonString['true'], 'bool_key');

        // 2. Map with null values in email lists
        final emailListMap = {
          'emails': ['first@example.com', null, 'second@example.com'],
        };
        final sanitizedEmails =
            exporter.sanitizeForJson(emailListMap, sanitizePii: true)
                as Map<String, dynamic>;
        final emails = sanitizedEmails['emails'] as List;
        expect(emails[0], 'f***t@example.com');
        expect(emails[1], isNull);
        expect(emails[2], 's***d@example.com');

        // 3. Email key with non-string, non-iterable value
        final emailNumberMap = {'email': 12345};
        final sanitizedEmailNumber =
            exporter.sanitizeForJson(emailNumberMap, sanitizePii: true)
                as Map<String, dynamic>;
        expect(sanitizedEmailNumber['email'], 12345);

        // 4. Nested maps and iterables containing email keys
        final nestedMap = {
          'user': {
            'user_email': 'nested@example.com',
            'details': [
              {'secondary_email': 'support@example.com'},
            ],
          },
        };
        final sanitizedNested =
            exporter.sanitizeForJson(nestedMap, sanitizePii: true)
                as Map<String, dynamic>;
        final user = sanitizedNested['user'] as Map<String, dynamic>;
        expect(user['user_email'], 'n***d@example.com');
        final details = user['details'] as List;
        expect((details[0] as Map)['secondary_email'], 's***t@example.com');

        // 5. Catch-all fallback returns toString()
        final customObject = Uri(scheme: 'https', host: 'example.com');
        final fallback = exporter.sanitizeForJson(customObject);
        expect(fallback, 'https://example.com');
      },
    );

    test(
      'exportStateRaw includes metadata, auth, database, and event logs',
      () async {
        mockLogger.info('Test log event 1', category: 'auth');
        mockLogger.error('Test log event 2', category: 'cycle');

        final raw = await exporter.exportStateRaw();

        expect(raw.containsKey('exportMetadata'), isTrue);
        expect(raw.containsKey('auth'), isTrue);
        expect(raw.containsKey('databaseState'), isTrue);
        expect(raw.containsKey('eventLogs'), isTrue);

        final auth = raw['auth'] as Map<String, dynamic>;
        expect(auth['isSignedIn'], isTrue);
        expect(auth['uid'], 'husband_uid');
        expect(auth['activeChartId'], 'mock_shared_chart');

        final logs = raw['eventLogs'] as List;
        expect(logs.length, 2);
        expect(logs[0]['message'], 'Test log event 1');
        expect(logs[1]['message'], 'Test log event 2');
      },
    );

    test('exportStateJson produces valid, parseable formatted JSON', () async {
      mockLogger.info('JSON test log');
      final jsonString = await exporter.exportStateJson(pretty: true);

      expect(jsonString, isNotEmpty);
      final decoded = json.decode(jsonString) as Map<String, dynamic>;
      expect(decoded['auth']['uid'], 'husband_uid');
      expect(decoded['eventLogs'], isNotEmpty);
    });

    testWidgets(
      'shareDebugState invokes custom fileSaver with filename and JSON payload',
      (WidgetTester tester) async {
        String? savedFilename;
        List<int>? savedBytes;

        final testExporter = AppStateExporter(
          db: mockDb,
          logger: mockLogger,
          fileSaver: (filename, bytes) async {
            savedFilename = filename;
            savedBytes = bytes;
          },
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (ctx) => ElevatedButton(
                  onPressed: () => testExporter.shareDebugState(ctx),
                  child: const Text('Export'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Export'));
        await tester.pumpAndSettle();

        expect(savedFilename, isNotNull);
        expect(savedFilename, startsWith('debug_app_state_'));
        expect(savedFilename, endsWith('.json'));
        expect(savedBytes, isNotNull);

        final decoded =
            json.decode(utf8.decode(savedBytes!)) as Map<String, dynamic>;
        expect(decoded['auth']['uid'], 'husband_uid');
        expect(decoded['auth']['email'], 'h***d@example.com');
        final databaseState = decoded['databaseState'] as Map<String, dynamic>;
        expect(databaseState.containsKey('supplements'), isTrue);
        expect(databaseState.containsKey('supplementLogs'), isTrue);
      },
    );
  });

  group('AppStateExporter.exportStateRaw with FirebaseDatabaseService', () {
    late _FakeFirebaseAuth fakeAuth;
    late _FakeFirebaseFirestore fakeFirestore;
    late FirebaseDatabaseService firebaseService;
    late AppLogger mockLogger;
    late AppStateExporter exporter;

    setUp(() {
      fakeAuth = _FakeFirebaseAuth(
        currentUser: _FakeUser(uid: 'user_123', email: 'user@example.com'),
      );
      fakeFirestore = _FakeFirebaseFirestore();
      firebaseService = FirebaseDatabaseService(
        auth: fakeAuth,
        db: fakeFirestore,
      );
      mockLogger = AppLogger(maxCapacity: 100);
      exporter = AppStateExporter(db: firebaseService, logger: mockLogger);
    });

    test('reports NO_ACTIVE_CHART when user has no activeChartId', () async {
      fakeFirestore.store['users/user_123'] = {
        'uid': 'user_123',
        'email': 'user@example.com',
      };
      firebaseService.cachedChartId = null;

      final raw = await exporter.exportStateRaw();
      final dbState = raw['databaseState'] as Map<String, dynamic>;
      final diagnostics = dbState['diagnostics'] as Map<String, dynamic>;

      expect(dbState['userDoc'], {
        'uid': 'user_123',
        'email': 'user@example.com',
      });
      expect(dbState['activeChartDoc'], isNull);
      expect(diagnostics['hasUserDoc'], isTrue);
      expect(diagnostics['hasActiveChartDoc'], isFalse);
      expect(diagnostics['diagnosis'], startsWith('NO_ACTIVE_CHART:'));
    });

    test(
      'reports CHART_NOT_FOUND when activeChartId is set but chart doc does not exist',
      () async {
        fakeFirestore.store['users/user_123'] = {
          'uid': 'user_123',
          'chartId': 'missing_chart_1',
        };
        firebaseService.cachedChartId = 'missing_chart_1';

        final raw = await exporter.exportStateRaw();
        final dbState = raw['databaseState'] as Map<String, dynamic>;
        final diagnostics = dbState['diagnostics'] as Map<String, dynamic>;

        expect(dbState['activeChartDoc'], {
          '_exists': false,
          'id': 'missing_chart_1',
        });
        expect(diagnostics['hasActiveChartDoc'], isFalse);
        expect(diagnostics['diagnosis'], startsWith('CHART_NOT_FOUND:'));
      },
    );

    test(
      'reports USER_NOT_IN_CHART_USERIDS when chart exists but user is not in userIds',
      () async {
        fakeFirestore.store['users/user_123'] = {
          'uid': 'user_123',
          'chartId': 'chart_other',
        };
        fakeFirestore.store['charts/chart_other'] = {
          'id': 'chart_other',
          'ownerId': 'other_owner',
          'userIds': ['other_owner'],
        };
        firebaseService.cachedChartId = 'chart_other';

        final raw = await exporter.exportStateRaw();
        final dbState = raw['databaseState'] as Map<String, dynamic>;
        final diagnostics = dbState['diagnostics'] as Map<String, dynamic>;

        expect(dbState['activeChartDoc'], {
          'id': 'chart_other',
          'ownerId': 'other_owner',
          'userIds': ['other_owner'],
        });
        expect(diagnostics['hasActiveChartDoc'], isTrue);
        expect(diagnostics['isUserInActiveChartUserIds'], isFalse);
        expect(
          diagnostics['diagnosis'],
          startsWith('USER_NOT_IN_CHART_USERIDS:'),
        );
      },
    );

    test(
      'reports MEMBERSHIP_VALID and exports chart subcollections and invitations when user is in userIds',
      () async {
        fakeFirestore.store['users/user_123'] = {
          'uid': 'user_123',
          'email': 'user@example.com',
          'chartId': 'chart_valid',
        };
        fakeFirestore.store['charts/chart_valid'] = {
          'id': 'chart_valid',
          'ownerId': 'user_123',
          'userIds': ['user_123', 'partner_456'],
        };
        fakeFirestore.store['charts/chart_valid/cycles/cycle_1'] = {
          'id': 'cycle_1',
          'startDate': '2026-08-01',
        };
        fakeFirestore.store['charts/chart_valid/supplements/supp_1'] = {
          'id': 'supp_1',
          'name': 'Progesterone',
        };
        fakeFirestore.store['charts/chart_valid/supplementLogs/2026-08-01'] = {
          'dateKey': '2026-08-01',
        };
        fakeFirestore.store['invitations/user@example.com'] = {
          'invitationId': 'user@example.com',
          'chartId': 'chart_valid',
          'status': 'pending',
        };
        firebaseService.cachedChartId = 'chart_valid';

        final raw = await exporter.exportStateRaw();
        final dbState = raw['databaseState'] as Map<String, dynamic>;
        final diagnostics = dbState['diagnostics'] as Map<String, dynamic>;

        expect(dbState['userDoc']['uid'], 'user_123');
        expect(dbState['activeChartDoc']['id'], 'chart_valid');
        expect((dbState['cycles'] as List).length, 1);
        expect((dbState['supplements'] as List).length, 1);
        expect((dbState['supplementLogs'] as List).length, 1);
        expect((dbState['availableCharts'] as List).length, 1);
        expect((dbState['invitations'] as List).length, 1);
        expect(diagnostics['hasUserDoc'], isTrue);
        expect(diagnostics['hasActiveChartDoc'], isTrue);
        expect(diagnostics['isUserInActiveChartUserIds'], isTrue);
        expect(diagnostics['diagnosis'], startsWith('MEMBERSHIP_VALID:'));
      },
    );

    test(
      'populates error and logs warning when Firestore lookup throws',
      () async {
        fakeFirestore.getDocErrors['users/user_123'] = Exception(
          'permission-denied',
        );

        final raw = await exporter.exportStateRaw();
        final dbState = raw['databaseState'] as Map<String, dynamic>;

        expect(dbState['error'], contains('Error fetching Firestore state'));
        expect(dbState['stackTrace'], isNotNull);
        expect(
          mockLogger.logs.any(
            (log) =>
                log.level == LogLevel.warning &&
                log.message.contains('Error fetching Firestore state'),
          ),
          isTrue,
        );
      },
    );
  });
}
