import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petal_count/logic/models/observation.dart';

void main() {
  group('Observation Deserialization & Timestamp Parsing Tests', () {
    test('parses timestamp from Firestore Timestamp instance', () {
      final expectedDate = DateTime(2026, 8, 14, 12, 30, 45);
      final timestamp = Timestamp.fromDate(expectedDate);

      final map = {
        'id': 'obs_1',
        'timestamp': timestamp,
        'sensation': 'wet',
        'stretch': 'stretchy',
        'colors': ['clear'],
        'consistencies': ['lubricative'],
        'bleeding': 'none',
        'userId': 'user_123',
      };

      final obs = Observation.fromMap(map);
      expect(obs.id, 'obs_1');
      expect(obs.timestamp, expectedDate);
      expect(obs.sensation, Sensation.wet);
      expect(obs.stretch, Stretch.stretchy);
      expect(obs.colors, [MucusColor.clear]);
      expect(obs.consistencies, [Consistency.lubricative]);
    });

    test('parses timestamp from ISO 8601 String', () {
      final expectedDate = DateTime(2026, 8, 14, 10, 15, 0);
      final map = {
        'id': 'obs_2',
        'timestamp': expectedDate.toIso8601String(),
        'sensation': 'dry',
        'stretch': 'none',
        'bleeding': 'heavy',
        'userId': 'user_123',
      };

      final obs = Observation.fromMap(map);
      expect(obs.timestamp, expectedDate);
      expect(obs.bleeding, Bleeding.heavy);
    });

    test('parses timestamp from epoch num / int in milliseconds', () {
      final expectedMillis = 1786708800000;
      final expectedDate = DateTime.fromMillisecondsSinceEpoch(expectedMillis);
      final map = {
        'id': 'obs_3',
        'timestamp': expectedMillis,
        'sensation': 'damp',
        'stretch': 'none',
        'bleeding': 'none',
        'userId': 'user_123',
      };

      final obs = Observation.fromMap(map);
      expect(obs.timestamp, expectedDate);
      expect(obs.sensation, Sensation.damp);
    });

    test('parses timestamp from native DateTime instance', () {
      final expectedDate = DateTime(2026, 8, 14, 15, 0, 0);
      final map = {
        'id': 'obs_4',
        'timestamp': expectedDate,
        'sensation': 'shiny',
        'stretch': 'sticky',
        'bleeding': 'none',
        'userId': 'user_123',
      };

      final obs = Observation.fromMap(map);
      expect(obs.timestamp, expectedDate);
      expect(obs.sensation, Sensation.shiny);
    });

    test(
      'gracefully handles null, invalid, or malformed timestamp with fallback',
      () {
        final before = DateTime.now().subtract(const Duration(seconds: 1));
        final map = {
          'id': 'obs_5',
          'timestamp': 'invalid-date-string',
          'sensation': 'dry',
          'stretch': 'none',
          'bleeding': 'none',
          'userId': 'user_123',
        };

        final obs = Observation.fromMap(map);
        final after = DateTime.now().add(const Duration(seconds: 1));

        expect(obs.timestamp.isAfter(before), true);
        expect(obs.timestamp.isBefore(after), true);

        final nullMap = {
          'id': 'obs_6',
          'timestamp': null,
          'sensation': 'dry',
          'stretch': 'none',
          'bleeding': 'none',
          'userId': 'user_123',
        };

        final obsNull = Observation.fromMap(nullMap);
        expect(obsNull.timestamp.isAfter(before), true);
        expect(obsNull.timestamp.isBefore(after), true);
      },
    );

    test(
      'preserves timestamp and properties through toMap and fromMap roundtrip',
      () {
        final originalDate = DateTime(2026, 8, 14, 18, 45, 0);
        final original = Observation(
          id: 'obs_roundtrip',
          timestamp: originalDate,
          sensation: Sensation.wet,
          stretch: Stretch.stretchy,
          colors: [MucusColor.clear, MucusColor.cloudy],
          consistencies: [Consistency.lubricative],
          bleeding: Bleeding.spotting,
          bleedingColor: 'B',
          painLevel: 4.5,
          painTypes: ['Cramps', 'Lower Back Pain'],
          comment: 'Evening observation',
          userId: 'user_456',
          isVdrsExplicit: true,
        );

        final map = original.toMap();
        expect(map['timestamp'], isA<Timestamp>());
        expect((map['timestamp'] as Timestamp).toDate(), originalDate);

        final restored = Observation.fromMap(map);
        expect(restored.id, original.id);
        expect(restored.timestamp, original.timestamp);
        expect(restored.sensation, original.sensation);
        expect(restored.stretch, original.stretch);
        expect(restored.colors, original.colors);
        expect(restored.consistencies, original.consistencies);
        expect(restored.bleeding, original.bleeding);
        expect(restored.bleedingColor, original.bleedingColor);
        expect(restored.painLevel, original.painLevel);
        expect(restored.painTypes, original.painTypes);
        expect(restored.comment, original.comment);
        expect(restored.userId, original.userId);
        expect(restored.isVdrsExplicit, original.isVdrsExplicit);
      },
    );
  });
}
