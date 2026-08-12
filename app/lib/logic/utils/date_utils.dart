/// Utility functions and extensions for DateTime operations and ISO date
/// parsing.

/// Extension providing date normalization helpers for [DateTime] instances.
extension DateTimeNormalizationX on DateTime {
  /// Normalizes DateTime to local midnight (Year, Month, Day) with 00:00:00
  /// time component.
  DateTime toNormalizedDate() {
    return DateTime(year, month, day);
  }

  /// Safely parses an ISO 8601 date string or YYYY-MM-DD date string with
  /// fallback handling.
  static DateTime parseIso(String dateStr) => parseIsoDate(dateStr);
}

/// Safely parses an ISO 8601 date string or YYYY-MM-DD date string with
/// fallback handling.
DateTime parseIsoDate(String dateStr) {
  try {
    return DateTime.parse(dateStr);
  } catch (_) {
    final dateOnly = dateStr.contains('T') ? dateStr.split('T')[0] : dateStr;
    final parts = dateOnly.split('-');
    if (parts.length >= 3) {
      final year = int.tryParse(parts[0]) ?? 1970;
      final month = int.tryParse(parts[1]) ?? 1;
      final day = int.tryParse(parts[2].replaceAll(RegExp(r'\D.*'), '')) ?? 1;
      return DateTime(year, month, day);
    }
    return DateTime.now();
  }
}
