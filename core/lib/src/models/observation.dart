import 'package:collection/collection.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'observation.freezed.dart';
part 'observation.g.dart';

enum Sensation {
  dry('0', 'Dry'),
  damp('2', 'Damp'),
  wet('2W', 'Wet'),
  shiny('4', 'Shiny');

  final String code;
  final String label;
  const Sensation(this.code, this.label);
}

enum Stretch {
  none('0', 'None'),
  sticky('6', 'Sticky (up to 1/4 inch)'),
  tacky('8', 'Tacky (1/2 to 3/4 inch)'),
  stretchy('10', 'Stretchy (1 inch or more)');

  final String code;
  final String label;
  const Stretch(this.code, this.label);
}

enum MucusColor {
  clear('K', 'Clear'),
  cloudy('C', 'Cloudy'),
  yellow('Y', 'Yellow'),
  red('R', 'Red'),
  brown('B', 'Brown');

  final String code;
  final String label;
  const MucusColor(this.code, this.label);
}

enum Consistency {
  gummy('G', 'Gummy'),
  pasty('P', 'Pasty'),
  lubricative('L', 'Lubricative');

  final String code;
  final String label;
  const Consistency(this.code, this.label);
}

enum Bleeding {
  none('', 'None'),
  heavy('H', 'Heavy'),
  moderate('M', 'Moderate'),
  light('L', 'Light'),
  veryLight('VL', 'Very Light'),
  spotting('VL', 'Spotting'),
  black('K', 'Black bleeding'),
  brown('B', 'Brown bleeding'),
  red('R', 'Red bleeding');

  final String code;
  final String label;
  const Bleeding(this.code, this.label);

  int get flowIntensity {
    switch (this) {
      case Bleeding.heavy:
        return 4;
      case Bleeding.moderate:
        return 3;
      case Bleeding.light:
        return 2;
      case Bleeding.veryLight:
      case Bleeding.spotting:
        return 1;
      case Bleeding.none:
      case Bleeding.black:
      case Bleeding.brown:
      case Bleeding.red:
        return 0;
    }
  }

  bool get isMenstrualFlow => flowIntensity >= 2;
}

enum Frequency {
  none('', 'None / Not Specified'),
  once('x1', 'Once (x1)'),
  twice('x2', 'Twice (x2)'),
  thrice('x3', 'Three times (x3)'),
  allDay('AD', 'All Day (AD)');

  final String code;
  final String label;
  const Frequency(this.code, this.label);
}

DateTime _parseTimestampFromJson(Object? timestampValue) {
  if (timestampValue is DateTime) {
    return timestampValue;
  } else if (timestampValue is String) {
    return DateTime.tryParse(timestampValue) ?? DateTime.now();
  } else if (timestampValue is num) {
    return DateTime.fromMillisecondsSinceEpoch(timestampValue.toInt());
  } else if (timestampValue is Map) {
    final seconds = timestampValue['seconds'] ?? timestampValue['_seconds'];
    final nanoseconds =
        timestampValue['nanoseconds'] ?? timestampValue['_nanoseconds'] ?? 0;
    if (seconds is num && nanoseconds is num) {
      return DateTime.fromMicrosecondsSinceEpoch(
        seconds.toInt() * 1000000 + (nanoseconds.toInt() ~/ 1000),
      );
    }
  } else if (timestampValue != null) {
    try {
      final dynamic dynamicTimestamp = timestampValue;
      final dynamic converted = dynamicTimestamp.toDate();
      if (converted is DateTime) {
        return converted;
      }
    } catch (_) {
      // Fall through to default when object does not provide a toDate() method.
    }
  }
  return DateTime.now();
}

Object _serializeTimestampToJson(DateTime dateTime) =>
    Observation.timestampSerializer(dateTime);

Sensation _parseSensationFromJson(Object? value) => Sensation.values.firstWhere(
  (element) => element.name == value,
  orElse: () => Sensation.dry,
);

Stretch _parseStretchFromJson(Object? value) => Stretch.values.firstWhere(
  (element) => element.name == value,
  orElse: () => Stretch.none,
);

List<MucusColor> _parseMucusColorsFromJson(Object? value) {
  if (value is! List) return const [];
  return value
      .map(
        (item) => MucusColor.values.firstWhereOrNull(
          (element) => element.name == item,
        ),
      )
      .whereType<MucusColor>()
      .toList();
}

List<Consistency> _parseConsistenciesFromJson(Object? value) {
  if (value is! List) return const [];
  return value
      .map(
        (item) => Consistency.values.firstWhereOrNull(
          (element) => element.name == item,
        ),
      )
      .whereType<Consistency>()
      .toList();
}

Bleeding _parseBleedingFromJson(Object? value) => Bleeding.values.firstWhere(
  (element) => element.name == value,
  orElse: () => Bleeding.none,
);

Frequency _parseFrequencyFromJson(Object? value) => Frequency.values.firstWhere(
  (element) => element.name == value,
  orElse: () => Frequency.none,
);

bool _parseBooleanWithDefaultFalse(Object? rawValue) {
  if (rawValue is bool) return rawValue;
  if (rawValue is String) return rawValue.trim().toLowerCase() == 'true';
  if (rawValue is num) return rawValue != 0;
  return false;
}

double _parseDoubleWithDefaultZero(Object? rawValue) {
  if (rawValue is num) return rawValue.toDouble();
  if (rawValue is String) return double.tryParse(rawValue) ?? 0.0;
  return 0.0;
}

List<String> _parseStringListFromJson(Object? rawValue) {
  if (rawValue is! List) return const [];
  return rawValue.map((item) => item.toString()).toList();
}

String _parseStringWithDefaultEmpty(Object? rawValue) =>
    rawValue?.toString() ?? '';

@freezed
abstract class Observation with _$Observation {
  const Observation._();

  /// Customizable hook for serializing [timestamp] in [toJson] / [toMap].
  /// Defaults to ISO 8601 string in pure Dart, and can be overridden by
  /// platform adapters (e.g. `Timestamp.fromDate` in Flutter) when needed.
  static Object Function(DateTime dateTime) timestampSerializer =
      (dateTime) => dateTime.toIso8601String();

  const factory Observation.raw({
    @Default('') @JsonKey(fromJson: _parseStringWithDefaultEmpty) String id,
    @JsonKey(
      fromJson: _parseTimestampFromJson,
      toJson: _serializeTimestampToJson,
    )
    required DateTime timestamp,
    @Default(Sensation.dry)
    @JsonKey(fromJson: _parseSensationFromJson)
    Sensation sensation,
    @Default(Stretch.none)
    @JsonKey(fromJson: _parseStretchFromJson)
    Stretch stretch,
    @Default(<MucusColor>[])
    @JsonKey(fromJson: _parseMucusColorsFromJson)
    List<MucusColor> colors,
    @Default(<Consistency>[])
    @JsonKey(fromJson: _parseConsistenciesFromJson)
    List<Consistency> consistencies,
    @Default(Bleeding.none)
    @JsonKey(fromJson: _parseBleedingFromJson)
    Bleeding bleeding,
    @Default('')
    @JsonKey(fromJson: _parseStringWithDefaultEmpty)
    String bleedingColor,
    @Default(Frequency.none)
    @JsonKey(fromJson: _parseFrequencyFromJson)
    Frequency frequency,
    @Default(false)
    @JsonKey(fromJson: _parseBooleanWithDefaultFalse)
    bool intercourse,
    @Default(0.0)
    @JsonKey(fromJson: _parseDoubleWithDefaultZero)
    double painLevel,
    @Default(<String>[])
    @JsonKey(fromJson: _parseStringListFromJson)
    List<String> painTypes,
    @Default('')
    @JsonKey(fromJson: _parseStringWithDefaultEmpty)
    String comment,
    @Default('') @JsonKey(fromJson: _parseStringWithDefaultEmpty) String userId,
    @JsonKey(includeIfNull: false) String? userRole,
    required bool isVdrsExplicit,
  }) = _Observation;

  factory Observation({
    required String id,
    required DateTime timestamp,
    required Sensation sensation,
    required Stretch stretch,
    required List<MucusColor> colors,
    required List<Consistency> consistencies,
    required Bleeding bleeding,
    String bleedingColor = '',
    Frequency frequency = Frequency.none,
    bool intercourse = false,
    double painLevel = 0.0,
    List<String> painTypes = const [],
    String comment = '',
    required String userId,
    String? userRole,
    bool? isVdrsExplicit,
  }) {
    final resolvedExplicit =
        isVdrsExplicit ??
        (bleeding != Bleeding.none ||
            stretch != Stretch.none ||
            colors.isNotEmpty ||
            consistencies.isNotEmpty ||
            sensation != Sensation.dry ||
            frequency != Frequency.none ||
            intercourse);
    return Observation.raw(
      id: id,
      timestamp: timestamp,
      sensation: sensation,
      stretch: stretch,
      colors: colors,
      consistencies: consistencies,
      bleeding: bleeding,
      bleedingColor: bleedingColor,
      frequency: frequency,
      intercourse: intercourse,
      painLevel: painLevel,
      painTypes: painTypes,
      comment: comment,
      userId: userId,
      userRole: userRole,
      isVdrsExplicit: resolvedExplicit,
    );
  }

  bool get hasMucus =>
      stretch != Stretch.none || consistencies.isNotEmpty || colors.isNotEmpty;
  bool get hasBleeding => bleeding != Bleeding.none;
  bool get isMenstrualFlow => bleeding.isMenstrualFlow;

  // Generates the standard VDRS code for this specific observation
  String get vdrsCode {
    if (!isVdrsExplicit && !intercourse && frequency == Frequency.none) {
      return '';
    }
    String code;
    if (hasBleeding) {
      final bleedingBaseCode = bleeding.code;
      final colorSuffix = (bleedingColor.isNotEmpty && bleedingColor != 'R')
          ? '-$bleedingColor'
          : '';
      final bleedingPart = '$bleedingBaseCode$colorSuffix';

      final isVeryLightOrSpotting =
          bleeding == Bleeding.veryLight || bleeding == Bleeding.spotting;

      if (isVeryLightOrSpotting ||
          hasMucus ||
          (sensation != Sensation.dry && isVdrsExplicit) ||
          (frequency != Frequency.none && isVdrsExplicit)) {
        code = '$bleedingPart ${mucusPart()}';
      } else {
        code = bleedingPart;
      }
    } else {
      code = mucusPart();
    }

    if (frequency != Frequency.none) {
      code = code.isEmpty ? frequency.code : '$code ${frequency.code}';
    }

    if (intercourse) {
      code = code.isEmpty ? 'I' : '$code I';
    }

    return code;
  }

  String mucusPart() {
    if (!hasMucus) {
      return sensation.code;
    }

    final containsLubricative = consistencies.contains(Consistency.lubricative);
    final containsPasty = consistencies.contains(Consistency.pasty);
    final containsGummy = consistencies.contains(Consistency.gummy);
    final hasPeakMucusAttributes =
        containsLubricative ||
        stretch == Stretch.stretchy ||
        colors.contains(MucusColor.clear);

    // Standard Creighton VDRS rules: Pasty (P) and Gummy (G) without Peak-type
    // overrides map to sticky (6) & cloudy (C), producing 6CP, 6CG, or 6CGP.
    if (!hasPeakMucusAttributes &&
        stretch != Stretch.tacky &&
        (containsPasty || containsGummy)) {
      if (containsPasty && containsGummy) {
        return '6CGP';
      }
      if (containsPasty) {
        return '6CP';
      }
      if (containsGummy) {
        return '6CG';
      }
    }

    final stretchCode = stretch.code;

    // Color string (e.g. "C/K" or "C" or "Y")
    final colorString = colors.isEmpty
        ? (stretch != Stretch.none ? 'C' : '')
        : colors.map((color) => color.code).join('/');

    // If it contains Lubricative, form 10DL, 10SL, 10WL (Lubricative sensation upgrades to 10 Peak-type)
    if (containsLubricative) {
      String sensationAbbreviation = '';
      if (sensation == Sensation.damp) sensationAbbreviation = 'D';
      if (sensation == Sensation.shiny) sensationAbbreviation = 'S';
      if (sensation == Sensation.wet) sensationAbbreviation = 'W';

      final lubricativeCode = '10${sensationAbbreviation}L';

      final otherConsistencies = consistencies
          .where((consistency) => consistency != Consistency.lubricative)
          .map((consistency) => consistency.code)
          .join('');

      return '$lubricativeCode$colorString$otherConsistencies';
    }

    final consistencyString = consistencies
        .map((consistency) => consistency.code)
        .join('');
    return '$stretchCode$colorString$consistencyString';
  }

  // Check if this specific observation is Peak-type mucus
  bool get isPeakType {
    if (!hasMucus) return false;
    final hasClear = colors.contains(MucusColor.clear);
    final isStretchy = stretch == Stretch.stretchy;
    final hasLubricative = consistencies.contains(Consistency.lubricative);
    return hasClear || isStretchy || hasLubricative;
  }

  factory Observation.fromJson(Map<String, dynamic> json) =>
      _$ObservationFromJson(json);

  factory Observation.fromMap(Map<String, dynamic> map) {
    final normalizedMap = Map<String, dynamic>.from(map);
    if (normalizedMap['isVdrsExplicit'] is! bool) {
      final parsedSensation = _parseSensationFromJson(
        normalizedMap['sensation'],
      );
      final parsedStretch = _parseStretchFromJson(normalizedMap['stretch']);
      final parsedColors = _parseMucusColorsFromJson(normalizedMap['colors']);
      final parsedConsistencies = _parseConsistenciesFromJson(
        normalizedMap['consistencies'],
      );
      final parsedBleeding = _parseBleedingFromJson(normalizedMap['bleeding']);
      final parsedFrequency = _parseFrequencyFromJson(
        normalizedMap['frequency'],
      );
      final parsedIntercourse = _parseBooleanWithDefaultFalse(
        normalizedMap['intercourse'],
      );
      normalizedMap['isVdrsExplicit'] =
          parsedBleeding != Bleeding.none ||
          parsedStretch != Stretch.none ||
          parsedColors.isNotEmpty ||
          parsedConsistencies.isNotEmpty ||
          parsedSensation != Sensation.dry ||
          parsedFrequency != Frequency.none ||
          parsedIntercourse;
    }
    return Observation.fromJson(normalizedMap);
  }

  Map<String, dynamic> toMap() => toJson();
}
