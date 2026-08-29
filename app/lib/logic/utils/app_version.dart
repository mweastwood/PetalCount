import 'package:flutter/foundation.dart';

class AppVersion {
  static const String rawVersion = String.fromEnvironment(
    'APP_VERSION',
    defaultValue: 'v0.0.0-dev',
  );

  static const String rawGitHash = String.fromEnvironment(
    'GIT_HASH',
    defaultValue: '',
  );

  static String get current => rawVersion;

  static String get gitHash => rawGitHash;

  static String get shortGitHash => formatShortGitHash(rawGitHash);

  static String get display => formatDisplay(rawVersion, rawGitHash);

  @visibleForTesting
  static String formatShortGitHash(String gitHash) {
    return gitHash.length >= 7 ? gitHash.substring(0, 7) : gitHash;
  }

  @visibleForTesting
  static String formatDisplay(String rawVersion, String gitHash) {
    final shortHash = formatShortGitHash(gitHash);
    if (shortHash.isNotEmpty) {
      return '$rawVersion ($shortHash)';
    }
    return rawVersion;
  }
}
