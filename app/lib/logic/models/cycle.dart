import 'daily_entry.dart';

class Cycle {
  final String id;
  final DateTime startDate;
  final DateTime? endDate;
  final List<String> bipCodes; // e.g., ['6-C', '8-Y']
  final Map<String, DailyEntry> dailyEntries; // Key: 'YYYY-MM-DD'

  Cycle({
    required this.id,
    required this.startDate,
    this.endDate,
    this.bipCodes = const [],
    this.dailyEntries = const {},
  });

  bool get isActive => endDate == null;

  List<DailyEntry> get sortedEntries {
    final list = dailyEntries.values.toList();
    list.sort((a, b) => a.date.compareTo(b.date));
    return list;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'startDate': startDate.toIso8601String().substring(0, 10),
      'endDate': endDate?.toIso8601String().substring(0, 10),
      'bipCodes': bipCodes,
      'dailyEntries': dailyEntries.map((k, v) => MapEntry(k, v.toMap())),
    };
  }

  factory Cycle.fromMap(Map<String, dynamic> map) {
    final startStr = map['startDate'] as String;
    final startParts = startStr.split('-');
    final parsedStart = DateTime(
      int.parse(startParts[0]),
      int.parse(startParts[1]),
      int.parse(startParts[2]),
    );

    DateTime? parsedEnd;
    if (map['endDate'] != null) {
      final endStr = map['endDate'] as String;
      final endParts = endStr.split('-');
      parsedEnd = DateTime(
        int.parse(endParts[0]),
        int.parse(endParts[1]),
        int.parse(endParts[2]),
      );
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
