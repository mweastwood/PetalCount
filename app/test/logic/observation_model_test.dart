import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Observation Firestore Timestamp Integration Tests', () {
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
  });
}
