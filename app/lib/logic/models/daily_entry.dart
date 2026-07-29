import 'observation.dart';

enum StampType {
  red('Red', 'Bleeding'),
  green('Green', 'Dry (Infertile)'),
  whiteBaby('WhiteBaby', 'Mucus (Fertile)'),
  greenBaby('GreenBaby', 'Post-Peak Dry (Fertile)'),
  yellow('Yellow', 'BIP Mucus (Infertile)'),
  yellowBaby('YellowBaby', 'Mucus Change (Fertile)');

  final String name;
  final String label;
  const StampType(this.name, this.label);
}

class DailyEntry {
  final DateTime date; // Year, Month, Day only
  final String resolvedVdrsCode;
  final StampType stampType;
  final List<Observation> observations;
  final double painLevel;
  final List<String> painTypes;
  final String comments;
  final String? peakDayLabel; // 'P', '1', '2', '3', or null

  DailyEntry({
    required this.date,
    required this.resolvedVdrsCode,
    required this.stampType,
    required this.observations,
    required this.painLevel,
    required this.painTypes,
    required this.comments,
    this.peakDayLabel,
  });

  bool get isPeakDay => peakDayLabel == 'P';
  bool get hasBleeding => resolvedVdrsCode.contains(RegExp(r'[HMLVSRB]'));

  Map<String, dynamic> toMap() {
    return {
      'date': date.toIso8601String().substring(0, 10),
      'resolvedVdrsCode': resolvedVdrsCode,
      'stampType': stampType.name,
      'observations': observations.map((o) => o.toMap()).toList(),
      'painLevel': painLevel,
      'painTypes': painTypes,
      'comments': comments,
      'peakDayLabel': peakDayLabel,
    };
  }

  factory DailyEntry.fromMap(Map<String, dynamic> map) {
    final dateStr = map['date'] as String;
    final parts = dateStr.split('-');
    final parsedDate = DateTime(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );

    return DailyEntry(
      date: parsedDate,
      resolvedVdrsCode: map['resolvedVdrsCode'] ?? '',
      stampType: StampType.values.firstWhere(
        (e) => e.name == map['stampType'],
        orElse: () => StampType.green,
      ),
      observations: ((map['observations'] as List?) ?? [])
          .map((item) => Observation.fromMap(Map<String, dynamic>.from(item)))
          .toList(),
      painLevel: (map['painLevel'] as num?)?.toDouble() ?? 0.0,
      painTypes: List<String>.from(map['painTypes'] ?? []),
      comments: map['comments'] ?? '',
      peakDayLabel: map['peakDayLabel'],
    );
  }

  DailyEntry copyWith({
    DateTime? date,
    String? resolvedVdrsCode,
    StampType? stampType,
    List<Observation>? observations,
    double? painLevel,
    List<String>? painTypes,
    String? comments,
    String? peakDayLabel,
  }) {
    return DailyEntry(
      date: date ?? this.date,
      resolvedVdrsCode: resolvedVdrsCode ?? this.resolvedVdrsCode,
      stampType: stampType ?? this.stampType,
      observations: observations ?? this.observations,
      painLevel: painLevel ?? this.painLevel,
      painTypes: painTypes ?? this.painTypes,
      comments: comments ?? this.comments,
      peakDayLabel: peakDayLabel ?? this.peakDayLabel,
    );
  }
}
