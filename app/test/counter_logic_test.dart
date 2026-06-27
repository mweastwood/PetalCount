import 'package:flutter_test/flutter_test.dart';
import 'package:petal_count/counter_logic.dart';

void main() {
  group('CounterLogic', () {
    test('starts at 0 with plural label', () {
      final logic = CounterLogic();
      expect(logic.count, 0);
      expect(logic.label, '0 petals counted');
    });

    test('increments count and formats label correctly', () {
      final logic = CounterLogic();

      logic.increment();
      expect(logic.count, 1);
      expect(logic.label, '1 petal counted');

      logic.increment();
      expect(logic.count, 2);
      expect(logic.label, '2 petals counted');
    });
  });
}
