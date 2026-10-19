import 'package:freezed_annotation/freezed_annotation.dart';

import '../utils/date_utils.dart';
import 'observation.dart';

part 'daily_entry.freezed.dart';
part 'daily_entry.g.dart';

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

DateTime _parseNormalizedDateFromJson(Object? rawDate) =>
    parseIsoDate(rawDate?.toString() ?? '');

String _serializeDateToDateKey(DateTime date) => date.dateKey;

StampType _parseStampTypeFromJson(Object? rawStampType) =>
    StampType.values.firstWhere(
      (element) => element.name == rawStampType,
      orElse: () => StampType.green,
    );

String _serializeStampTypeToJson(StampType stampType) => stampType.name;

List<Observation> _parseObservationsFromJson(Object? rawObservations) {
  if (rawObservations is! List) return const [];
  return rawObservations
      .whereType<Map>()
      .map((item) => Observation.fromMap(Map<String, dynamic>.from(item)))
      .toList();
}

List<Map<String, dynamic>> _serializeObservationsToJson(
  List<Observation> observations,
) => observations.map((observation) => observation.toMap()).toList();

double _parsePainLevelFromJson(Object? rawValue) {
  if (rawValue is num) return rawValue.toDouble();
  if (rawValue is String) return double.tryParse(rawValue) ?? 0.0;
  return 0.0;
}

List<String> _parsePainTypesFromJson(Object? rawValue) {
  if (rawValue is! List) return const [];
  return rawValue.map((item) => item.toString()).toList();
}

String _parseStringFromJson(Object? rawValue) => rawValue?.toString() ?? '';

@freezed
abstract class DailyEntry with _$DailyEntry {
  const DailyEntry._();

  const factory DailyEntry.raw({
    @JsonKey(
      fromJson: _parseNormalizedDateFromJson,
      toJson: _serializeDateToDateKey,
    )
    required DateTime date,
    @Default('')
    @JsonKey(fromJson: _parseStringFromJson)
    String resolvedVdrsCode,
    @Default(StampType.green)
    @JsonKey(
      fromJson: _parseStampTypeFromJson,
      toJson: _serializeStampTypeToJson,
    )
    StampType stampType,
    @Default(<Observation>[])
    @JsonKey(
      fromJson: _parseObservationsFromJson,
      toJson: _serializeObservationsToJson,
    )
    List<Observation> observations,
    @Default(0.0) @JsonKey(fromJson: _parsePainLevelFromJson) double painLevel,
    @Default(<String>[])
    @JsonKey(fromJson: _parsePainTypesFromJson)
    List<String> painTypes,
    @Default('') @JsonKey(fromJson: _parseStringFromJson) String comments,
    String? peakDayLabel,
  }) = _DailyEntry;

  factory DailyEntry({
    required DateTime date,
    required String resolvedVdrsCode,
    required StampType stampType,
    required List<Observation> observations,
    required double painLevel,
    required List<String> painTypes,
    required String comments,
    String? peakDayLabel,
  }) {
    return DailyEntry.raw(
      date: date.toNormalizedDate(),
      resolvedVdrsCode: resolvedVdrsCode,
      stampType: stampType,
      observations: observations,
      painLevel: painLevel,
      painTypes: painTypes,
      comments: comments,
      peakDayLabel: peakDayLabel,
    );
  }

  bool get isPeakDay => peakDayLabel == 'P';

  bool get hasBleeding =>
      observations.any((observation) => observation.hasBleeding);

  bool get hasMenstrualFlow =>
      observations.any((observation) => observation.isMenstrualFlow);

  bool get hasMucus => observations.any((observation) => observation.hasMucus);

  bool get isPeakType =>
      observations.any((observation) => observation.isPeakType);

  bool get hasIntercourse =>
      observations.any((observation) => observation.intercourse);

  factory DailyEntry.fromJson(Map<String, dynamic> json) =>
      _$DailyEntryFromJson(json);

  factory DailyEntry.fromMap(Map<String, dynamic> map) =>
      DailyEntry.fromJson(map);

  Map<String, dynamic> toMap() => toJson();
}
