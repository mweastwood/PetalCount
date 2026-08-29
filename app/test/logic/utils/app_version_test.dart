import 'package:flutter_test/flutter_test.dart';
import 'package:petal_count/logic/utils/app_version.dart';

void main() {
  group('AppVersion', () {
    group('Static Getters (Default Environment)', () {
      test('provides non-empty default version strings', () {
        expect(AppVersion.current, isNotEmpty);
        expect(AppVersion.current, equals(AppVersion.rawVersion));
        expect(AppVersion.gitHash, equals(AppVersion.rawGitHash));
        expect(
          AppVersion.shortGitHash,
          equals(AppVersion.formatShortGitHash(AppVersion.rawGitHash)),
        );
        expect(AppVersion.display, isNotEmpty);
        expect(AppVersion.display, equals(AppVersion.rawVersion));
      });

      test('shortGitHash length is less than or equal to 7', () {
        expect(AppVersion.shortGitHash.length, lessThanOrEqualTo(7));
      });
    });

    group('formatShortGitHash', () {
      test('returns empty string when input is empty', () {
        expect(AppVersion.formatShortGitHash(''), equals(''));
      });

      test('returns full hash when length is less than 7', () {
        expect(AppVersion.formatShortGitHash('a'), equals('a'));
        expect(AppVersion.formatShortGitHash('abc'), equals('abc'));
        expect(AppVersion.formatShortGitHash('123456'), equals('123456'));
      });

      test('returns exact hash when length is exactly 7', () {
        expect(AppVersion.formatShortGitHash('1234567'), equals('1234567'));
        expect(AppVersion.formatShortGitHash('abcdefg'), equals('abcdefg'));
      });

      test('truncates to first 7 characters when length is greater than 7', () {
        expect(AppVersion.formatShortGitHash('12345678'), equals('1234567'));
        expect(
          AppVersion.formatShortGitHash(
            '0123456789abcdef0123456789abcdef01234567',
          ),
          equals('0123456'),
        );
      });
    });

    group('formatDisplay', () {
      test('returns only rawVersion when git hash is empty', () {
        expect(AppVersion.formatDisplay('v1.0.0', ''), equals('v1.0.0'));
        expect(AppVersion.formatDisplay('1.2.3+4', ''), equals('1.2.3+4'));
        expect(
          AppVersion.formatDisplay('v0.0.1-beta', ''),
          equals('v0.0.1-beta'),
        );
      });

      test(
        'appends short git hash in parentheses when hash length is less than 7',
        () {
          expect(
            AppVersion.formatDisplay('v1.0.0', 'abc'),
            equals('v1.0.0 (abc)'),
          );
          expect(
            AppVersion.formatDisplay('v1.0.0', '123456'),
            equals('v1.0.0 (123456)'),
          );
        },
      );

      test(
        'appends exact 7-char hash in parentheses when hash length is exactly 7',
        () {
          expect(
            AppVersion.formatDisplay('v1.0.0', '1234567'),
            equals('v1.0.0 (1234567)'),
          );
        },
      );

      test(
        'appends truncated 7-char git hash in parentheses when hash length is greater than 7',
        () {
          expect(
            AppVersion.formatDisplay(
              'v1.0.0',
              '0123456789abcdef0123456789abcdef01234567',
            ),
            equals('v1.0.0 (0123456)'),
          );
          expect(
            AppVersion.formatDisplay('2.0.0-rc.1', 'abcdef012345'),
            equals('2.0.0-rc.1 (abcdef0)'),
          );
        },
      );
    });
  });
}
