import 'package:intl/intl.dart';

// Utility functions and extensions for DateTime operations and ISO date
// parsing.

/// Extension providing date normalization helpers for [DateTime] instances.
extension DateTimeNormalizationX on DateTime {
  /// Normalizes DateTime to local midnight (Year, Month, Day) with 00:00:00
  /// time component.
  DateTime toNormalizedDate() {
    return DateTime(year, month, day);
  }

  /// Normalizes DateTime to UTC midnight (Year, Month, Day) with 00:00:00Z
  /// time component.
  DateTime toUtcDate() {
    return DateTime.utc(year, month, day);
  }

  /// Computes calendar days from [other] to this date (`this - other`).
  int calendarDaysSince(DateTime other) {
    return calendarDaysBetween(other, this);
  }

  /// Computes calendar days from this date to [other] (`other - this`).
  int calendarDaysTo(DateTime other) {
    return calendarDaysBetween(this, other);
  }

  /// Adds [days] calendar days without clock drift or DST 23/25-hour duration issues.
  DateTime addCalendarDays(int days) {
    return isUtc
        ? DateTime.utc(year, month, day + days)
        : DateTime(year, month, day + days);
  }

  /// Subtracts [days] calendar days without clock drift or DST 23/25-hour duration issues.
  DateTime subtractCalendarDays(int days) {
    return isUtc
        ? DateTime.utc(year, month, day - days)
        : DateTime(year, month, day - days);
  }

  /// Safely parses an ISO 8601 date string or YYYY-MM-DD date string with
  /// fallback handling.
  static DateTime parseIso(String dateStr) => parseIsoDate(dateStr);
}

/// Extension providing standardized date key formatting for [DateTime] instances.
extension DateFormattingX on DateTime {
  /// Returns a standardized 'yyyy-MM-dd' string key for cycle daily entry maps.
  String get dateKey =>
      '${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
}

/// Consolidated static cache of [DateFormat] singletons across the application.
class AppDateFormats {
  static final DateFormat isoDate = DateFormat('yyyy-MM-dd');
  static final DateFormat shortMonthDay = DateFormat('MMM dd');
  static final DateFormat monthYear = DateFormat('MMMM yyyy');
  static final DateFormat fullDate = DateFormat('EEEE, MMM dd, yyyy');
  static final DateFormat monthDayYear = DateFormat('MMMM dd, yyyy');
  static final DateFormat shortMonthDayYear = DateFormat('MMM dd, yyyy');
  static final DateFormat weekdayMonthDay = DateFormat('EEEE, MMM dd');
  static final DateFormat dateTimeWithTime = DateFormat(
    'MMM dd, yyyy • h:mm a',
  );
  static final DateFormat timeOfDay = DateFormat('h:mm a');
  static final DateFormat timeOfDayPadded = DateFormat('hh:mm a');
}

/// Calculates the number of calendar days between [from] and [to] (e.g. from
/// 2026-03-01 to 2026-03-02 is 1).
///
/// Normalizes both [DateTime] instances to UTC midnight (`DateTime.utc(year, month, day)`)
/// to prevent Daylight Saving Time (DST) 23-hour / 25-hour day truncation bugs.
int calendarDaysBetween(DateTime from, DateTime to) {
  final fromUtc = DateTime.utc(from.year, from.month, from.day);
  final toUtc = DateTime.utc(to.year, to.month, to.day);
  return toUtc.difference(fromUtc).inDays;
}

/// Safely parses an ISO 8601 date string or YYYY-MM-DD date string with
/// fallback handling.
DateTime parseIsoDate(String dateStr) {
  try {
    return DateTime.parse(dateStr).toNormalizedDate();
  } catch (_) {
    final dateOnly = dateStr.contains('T') ? dateStr.split('T')[0] : dateStr;
    final parts = dateOnly.split('-');
    if (parts.length >= 3) {
      final year = int.tryParse(parts[0]) ?? 1970;
      final month = int.tryParse(parts[1]) ?? 1;
      final day = int.tryParse(parts[2].replaceAll(RegExp(r'\D.*'), '')) ?? 1;
      return DateTime(year, month, day);
    }
    return DateTime(1970, 1, 1);
  }
}
