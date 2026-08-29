import '../utils/date_utils.dart';
import 'daily_entry.dart';

class Cycle {
  final String id;
  final DateTime startDate;
  final DateTime? endDate;
  final List<String> bipCodes; // e.g., ['6C', '8Y']
  final Map<String, DailyEntry> dailyEntries; // Key: 'YYYY-MM-DD'

  Cycle({
    required this.id,
    required DateTime startDate,
    DateTime? endDate,
    this.bipCodes = const [],
    this.dailyEntries = const {},
  }) : startDate = startDate.toNormalizedDate(),
       endDate = endDate?.toNormalizedDate();

  bool get isActive => endDate == null;

  List<DailyEntry> get sortedEntries {
    final list = dailyEntries.values.toList();
    list.sort((a, b) => a.date.compareTo(b.date));
    return list;
  }

  /// Calculates the maximum 1-based day index reached by entries or [endDate]
  /// relative to [startDate].
  int get maxDayNumber {
    int cycleMaxDay = 0;
    for (final entry in sortedEntries) {
      final dayNum = calendarDaysBetween(startDate, entry.date) + 1;
      if (dayNum > cycleMaxDay) {
        cycleMaxDay = dayNum;
      }
    }
    if (endDate != null) {
      final endDayNum = calendarDaysBetween(startDate, endDate!) + 1;
      if (endDayNum > cycleMaxDay) {
        cycleMaxDay = endDayNum;
      }
    }
    return cycleMaxDay;
  }

  /// Returns the 1-based day index for a specific date within the cycle.
  int dayNumberFor(DateTime date) {
    return calendarDaysBetween(startDate, date) + 1;
  }

  /// Calculates the global maximum display days across a collection of cycles,
  /// with a default minimum of [minDays] (default: 35).
  static int calculateMaxDisplayDays(
    Iterable<Cycle> cycles, {
    int minDays = 35,
  }) {
    int maxDays = minDays;
    final sorted = List<Cycle>.from(cycles)
      ..sort((a, b) => a.startDate.compareTo(b.startDate));

    for (int i = 0; i < sorted.length; i++) {
      final cycle = sorted[i];
      int cycleMax = cycle.maxDayNumber;
      if (cycle.endDate != null) {
        final endDays =
            calendarDaysBetween(cycle.startDate, cycle.endDate!) + 1;
        if (endDays > cycleMax) cycleMax = endDays;
      } else if (i < sorted.length - 1) {
        final nextStart = sorted[i + 1].startDate;
        final cycleDays = calendarDaysBetween(cycle.startDate, nextStart);
        if (cycleDays > cycleMax) cycleMax = cycleDays;
      }
      if (cycleMax > maxDays) {
        maxDays = cycleMax;
      }
    }
    return maxDays;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'startDate': startDate.dateKey,
      'endDate': endDate?.dateKey,
      'bipCodes': bipCodes,
      'dailyEntries': dailyEntries.map((k, v) => MapEntry(k, v.toMap())),
    };
  }

  factory Cycle.fromMap(Map<String, dynamic> map) {
    final startStr = map['startDate']?.toString() ?? '';
    final parsedStart = parseIsoDate(startStr);

    DateTime? parsedEnd;
    if (map['endDate'] != null) {
      parsedEnd = parseIsoDate(map['endDate'].toString());
    }

    final rawEntries = map['dailyEntries'] as Map? ?? {};
    final entries = <String, DailyEntry>{};
    rawEntries.forEach((k, v) {
      entries[k.toString()] = DailyEntry.fromMap(Map<String, dynamic>.from(v));
    });

    return Cycle(
      id: map['id'] ?? '',
      startDate: parsedStart,
      endDate: parsedEnd,
      bipCodes: List<String>.from(map['bipCodes'] ?? []),
      dailyEntries: entries,
    );
  }

  Cycle copyWith({
    String? id,
    DateTime? startDate,
    DateTime? endDate,
    List<String>? bipCodes,
    Map<String, DailyEntry>? dailyEntries,
  }) {
    return Cycle(
      id: id ?? this.id,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      bipCodes: bipCodes ?? this.bipCodes,
      dailyEntries: dailyEntries ?? this.dailyEntries,
    );
  }
}
