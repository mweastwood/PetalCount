import 'package:freezed_annotation/freezed_annotation.dart';

import '../utils/date_utils.dart';
import 'daily_entry.dart';

part 'cycle.freezed.dart';
part 'cycle.g.dart';

DateTime _parseCycleStartDateFromJson(Object? rawDate) =>
    parseIsoDate(rawDate?.toString() ?? '');

String _serializeCycleDateToDateKey(DateTime date) => date.dateKey;

DateTime? _parseCycleEndDateFromJson(Object? rawDate) {
  if (rawDate == null) return null;
  return parseIsoDate(rawDate.toString());
}

String? _serializeCycleEndDateToDateKey(DateTime? date) => date?.dateKey;

List<String> _parseBasicInfertilePatternCodesFromJson(Object? rawValue) {
  if (rawValue is! List) return const [];
  return rawValue.map((item) => item.toString()).toList();
}

Map<String, DailyEntry> _parseDailyEntriesFromJson(Object? rawEntries) {
  if (rawEntries is! Map) return const {};
  final entries = <String, DailyEntry>{};
  rawEntries.forEach((key, value) {
    if (value is Map) {
      final parsedEntry = DailyEntry.fromMap(Map<String, dynamic>.from(value));
      final normalizedKey = key.toString().isNotEmpty
          ? key.toString()
          : parsedEntry.date.dateKey;
      entries[normalizedKey] = parsedEntry;
    }
  });
  return entries;
}

Map<String, dynamic> _serializeDailyEntriesToJson(
  Map<String, DailyEntry> dailyEntries,
) => dailyEntries.map((key, entry) => MapEntry(key, entry.toMap()));

String _parseCycleIdFromJson(Object? rawId) => rawId?.toString() ?? '';

@freezed
abstract class Cycle with _$Cycle {
  const Cycle._();

  const factory Cycle.raw({
    @Default('') @JsonKey(fromJson: _parseCycleIdFromJson) String id,
    @JsonKey(
      fromJson: _parseCycleStartDateFromJson,
      toJson: _serializeCycleDateToDateKey,
    )
    required DateTime startDate,
    @JsonKey(
      fromJson: _parseCycleEndDateFromJson,
      toJson: _serializeCycleEndDateToDateKey,
    )
    DateTime? endDate,
    @Default(<String>[])
    @JsonKey(fromJson: _parseBasicInfertilePatternCodesFromJson)
    List<String> bipCodes,
    @Default(<String, DailyEntry>{})
    @JsonKey(
      fromJson: _parseDailyEntriesFromJson,
      toJson: _serializeDailyEntriesToJson,
    )
    Map<String, DailyEntry> dailyEntries,
  }) = _Cycle;

  factory Cycle({
    required String id,
    required DateTime startDate,
    DateTime? endDate,
    List<String> bipCodes = const [],
    Map<String, DailyEntry> dailyEntries = const {},
  }) {
    return Cycle.raw(
      id: id,
      startDate: startDate.toNormalizedDate(),
      endDate: endDate?.toNormalizedDate(),
      bipCodes: bipCodes,
      dailyEntries: dailyEntries,
    );
  }

  bool get isActive => endDate == null;

  static final Expando<List<DailyEntry>> _sortedEntriesCache =
      Expando<List<DailyEntry>>('Cycle.sortedEntries');

  List<DailyEntry> get sortedEntries {
    final cached = _sortedEntriesCache[this];
    if (cached != null) return cached;
    final list = List<DailyEntry>.unmodifiable(
      dailyEntries.values.toList()
        ..sort((first, second) => first.date.compareTo(second.date)),
    );
    _sortedEntriesCache[this] = list;
    return list;
  }

  /// Returns the date of the latest entry in this cycle, or null if [dailyEntries] is empty.
  DateTime? get maxEntryDate =>
      sortedEntries.isEmpty ? null : sortedEntries.last.date;

  /// Calculates the maximum 1-based day index reached by entries or [endDate]
  /// relative to [startDate].
  int get maxDayNumber {
    int cycleMaxDay = 0;
    for (final entry in sortedEntries) {
      final dayNumber = calendarDaysBetween(startDate, entry.date) + 1;
      if (dayNumber > cycleMaxDay) {
        cycleMaxDay = dayNumber;
      }
    }
    if (endDate != null) {
      final endDayNumber = calendarDaysBetween(startDate, endDate!) + 1;
      if (endDayNumber > cycleMaxDay) {
        cycleMaxDay = endDayNumber;
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
    final sortedCycles = List<Cycle>.from(cycles)
      ..sort((first, second) => first.startDate.compareTo(second.startDate));

    for (int index = 0; index < sortedCycles.length; index++) {
      final cycle = sortedCycles[index];
      int cycleMax = cycle.maxDayNumber;
      if (cycle.endDate != null) {
        final endDays =
            calendarDaysBetween(cycle.startDate, cycle.endDate!) + 1;
        if (endDays > cycleMax) cycleMax = endDays;
      } else if (index < sortedCycles.length - 1) {
        final nextStart = sortedCycles[index + 1].startDate;
        final cycleDays = calendarDaysBetween(cycle.startDate, nextStart);
        if (cycleDays > cycleMax) cycleMax = cycleDays;
      }
      if (cycleMax > maxDays) {
        maxDays = cycleMax;
      }
    }
    return maxDays;
  }

  factory Cycle.fromJson(Map<String, dynamic> json) => _$CycleFromJson(json);

  factory Cycle.fromMap(Map<String, dynamic> map) => Cycle.fromJson(map);

  Map<String, dynamic> toMap() => toJson();
}
