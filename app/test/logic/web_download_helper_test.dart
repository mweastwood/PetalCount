import 'package:flutter_test/flutter_test.dart';
import 'package:petal_count/logic/logic.dart';

void main() {
  test(
    'downloadFileWeb on non-web platforms runs as a no-op and does not throw',
    () {
      final bytes = [1, 2, 3, 4];
      const filename = 'test_file.pdf';

      // On VM / non-web, this should resolve to the stub and execute as a no-op
      expect(() => downloadFileWeb(bytes, filename), returnsNormally);
    },
  );
}
