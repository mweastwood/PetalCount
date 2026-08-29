import 'package:flutter_test/flutter_test.dart';
import 'package:petal_count/logic/app_config.dart';

void main() {
  group('AppConfig', () {
    setUp(() {
      // Reset to dev before each test to avoid order-dependency
      AppConfig.environment = AppEnvironment.dev;
    });

    tearDown(() {
      AppConfig.environment = AppEnvironment.dev;
    });

    test('default environment is dev', () {
      expect(AppConfig.environment, AppEnvironment.dev);
    });

    test('dev environment returns dev OAuth client ID', () {
      AppConfig.environment = AppEnvironment.dev;
      expect(
        AppConfig.googleServerClientId,
        '688587508865-fhe9rghlo1f909rn8t7vqjvld7km36sl.apps.googleusercontent.com',
      );
    });

    test('prod environment returns prod OAuth client ID', () {
      AppConfig.environment = AppEnvironment.prod;
      expect(
        AppConfig.googleServerClientId,
        '847947122489-kbpqd3e7m8b3aehd3ah9714rgsd10es3.apps.googleusercontent.com',
      );
    });

    test('dev and prod client IDs are distinct', () {
      AppConfig.environment = AppEnvironment.dev;
      final devId = AppConfig.googleServerClientId;

      AppConfig.environment = AppEnvironment.prod;
      final prodId = AppConfig.googleServerClientId;

      expect(devId, isNot(equals(prodId)));
    });

    test('all AppEnvironment values are handled exhaustively', () {
      // Ensures no environment returns null or empty string
      for (final env in AppEnvironment.values) {
        AppConfig.environment = env;
        expect(AppConfig.googleServerClientId, isNotEmpty);
      }
    });
  });
}
