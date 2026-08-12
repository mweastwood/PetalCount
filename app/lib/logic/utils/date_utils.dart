// Utility functions and extensions for DateTime operations and ISO date
// parsing.

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
  final trimmed = dateStr.trim();
  if (trimmed.isEmpty) return DateTime(1970, 1, 1);

  final dateOnly = trimmed.contains('T')
      ? trimmed.split('T')[0]
      : (trimmed.contains(' ') ? trimmed.split(' ')[0] : trimmed);

  try {
    final parsed = DateTime.parse(dateOnly);
    return DateTime(parsed.year, parsed.month, parsed.day);
  } catch (_) {
    final parts = dateOnly.split('-');
    if (parts.length >= 3) {
      final year = int.tryParse(parts[0]);
      final month = int.tryParse(parts[1]);
      final dayStr = parts[2].replaceAll(RegExp(r'\D.*'), '');
      final day = int.tryParse(dayStr);
      if (year != null && month != null && day != null) {
        return DateTime(year, month, day);
      }
    }
    return DateTime(1970, 1, 1);
  }
}

