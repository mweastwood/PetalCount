import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petal_count/logic/app_logger.dart';
import 'package:petal_count/logic/app_state_exporter.dart';
import 'package:petal_count/logic/services/database/in_memory_database_service.dart';

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
      },
    );
  });
}
