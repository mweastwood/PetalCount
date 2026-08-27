import 'package:cloud_firestore/cloud_firestore.dart';

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

class Observation {
  final String id;
  final DateTime timestamp;
  final Sensation sensation;
  final Stretch stretch;
  final List<MucusColor> colors;
  final List<Consistency> consistencies;
  final Bleeding bleeding;
  final String bleedingColor; // 'R' for red, 'B' for brown, or empty
  final Frequency frequency;
  final bool intercourse;
  final double painLevel; // 0.0 to 10.0
  final List<String> painTypes; // e.g., ['Cramps', 'Ovulation Pain']
  final String comment;
  final String userId;
  final bool isVdrsExplicit;

  Observation({
    required this.id,
    required this.timestamp,
    required this.sensation,
    required this.stretch,
    required this.colors,
    required this.consistencies,
    required this.bleeding,
    this.bleedingColor = '',
    this.frequency = Frequency.none,
    this.intercourse = false,
    this.painLevel = 0.0,
    this.painTypes = const [],
    this.comment = '',
    required this.userId,
    bool? isVdrsExplicit,
  }) : isVdrsExplicit =
           isVdrsExplicit ??
           (bleeding != Bleeding.none ||
               stretch != Stretch.none ||
               colors.isNotEmpty ||
               consistencies.isNotEmpty ||
               sensation != Sensation.dry ||
               frequency != Frequency.none ||
               intercourse);

  bool get hasMucus =>
      stretch != Stretch.none ||
      consistencies.contains(Consistency.lubricative);
  bool get hasBleeding => bleeding != Bleeding.none;
  bool get isMenstrualFlow => bleeding.isMenstrualFlow;

  // Generates the standard VDRS code for this specific observation
  String get vdrsCode {
    if (!isVdrsExplicit && !intercourse && frequency == Frequency.none) {
      return '';
    }
    String code;
    if (hasBleeding) {
      final bCode = bleeding.code;
      final colorSuffix = (bleedingColor.isNotEmpty && bleedingColor != 'R')
          ? '-$bleedingColor'
          : '';
      final bleedingPart = '$bCode$colorSuffix';

      if (!hasMucus) {
        if ((sensation != Sensation.dry && isVdrsExplicit) ||
            (frequency != Frequency.none && isVdrsExplicit)) {
          code = '$bleedingPart ${mucusPart()}';
        } else {
          code = bleedingPart;
        }
      } else {
        // Combined bleeding and mucus (e.g. "L-R 10-K-L")
        code = '$bleedingPart ${mucusPart()}';
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
      // Just sensation
      return sensation.code;
    }

    // Standard Creighton VDRS rules: Pasty (P) and Gummy (G) are strictly sticky (6) & cloudy (C), producing 6CP, 6CG, or 6CGP
    final containsP = consistencies.contains(Consistency.pasty);
    final containsG = consistencies.contains(Consistency.gummy);
    if (containsP && containsG) {
      return '6CGP';
    }
    if (containsP) {
      return '6CP';
    }
    if (containsG) {
      return '6CG';
    }

    final stretchCode = stretch.code;

    // Color string (e.g. "C/K" or "C" or "Y")
    final colorStr = colors.isEmpty
        ? (stretch != Stretch.none ? 'C' : '')
        : colors.map((c) => c.code).join('/');

    // If it contains Lubricative, form 10DL, 10SL, 10WL (Lubricative sensation upgrades to 10 Peak-type)
    final containsL = consistencies.contains(Consistency.lubricative);
    if (containsL) {
      String sensAbbr = '';
      if (sensation == Sensation.damp) sensAbbr = 'D';
      if (sensation == Sensation.shiny) sensAbbr = 'S';
      if (sensation == Sensation.wet) sensAbbr = 'W';

      // Typically written as e.g. "10DL" or "10WL"
      final lubricativeCode = '10${sensAbbr}L';

      // If there are other consistencies or colors
      final otherConsistencies = consistencies
          .where((c) => c != Consistency.lubricative)
          .map((c) => c.code)
          .join('');

      return '$lubricativeCode$colorStr$otherConsistencies';
    }

    final consistencyStr = consistencies.map((c) => c.code).join('');
    return '$stretchCode$colorStr$consistencyStr';
  }

  // Check if this specific observation is Peak-type mucus
  bool get isPeakType {
    if (!hasMucus) return false;
    // Peak-type is clear (K), stretchy (10), or lubricative (L)
    final hasClear = colors.contains(MucusColor.clear);
    final isStretchy = stretch == Stretch.stretchy;
    final hasLubricative = consistencies.contains(Consistency.lubricative);
    return hasClear || isStretchy || hasLubricative;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'timestamp': Timestamp.fromDate(timestamp),
      'sensation': sensation.name,
      'stretch': stretch.name,
      'colors': colors.map((c) => c.name).toList(),
      'consistencies': consistencies.map((c) => c.name).toList(),
      'bleeding': bleeding.name,
      'bleedingColor': bleedingColor,
      'frequency': frequency.name,
      'intercourse': intercourse,
      'painLevel': painLevel,
      'painTypes': painTypes,
      'comment': comment,
      'userId': userId,
      'isVdrsExplicit': isVdrsExplicit,
    };
  }

  static DateTime _parseTimestamp(dynamic timestamp) {
    if (timestamp is Timestamp) {
      return timestamp.toDate();
    } else if (timestamp is DateTime) {
      return timestamp;
    } else if (timestamp is String) {
      return DateTime.tryParse(timestamp) ?? DateTime.now();
    } else if (timestamp is num) {
      return DateTime.fromMillisecondsSinceEpoch(timestamp.toInt());
    }
    return DateTime.now();
  }

  factory Observation.fromMap(Map<String, dynamic> map) {
    final sensation = Sensation.values.firstWhere(
      (e) => e.name == map['sensation'],
      orElse: () => Sensation.dry,
    );
    final stretch = Stretch.values.firstWhere(
      (e) => e.name == map['stretch'],
      orElse: () => Stretch.none,
    );
    final colors = ((map['colors'] as List?) ?? [])
        .map(
          (item) => MucusColor.values.cast<MucusColor?>().firstWhere(
            (e) => e?.name == item,
            orElse: () => null,
          ),
        )
        .whereType<MucusColor>()
        .toList();
    final consistencies = ((map['consistencies'] as List?) ?? [])
        .map(
          (item) => Consistency.values.cast<Consistency?>().firstWhere(
            (e) => e?.name == item,
            orElse: () => null,
          ),
        )
        .whereType<Consistency>()
        .toList();
    final bleeding = Bleeding.values.firstWhere(
      (e) => e.name == map['bleeding'],
      orElse: () => Bleeding.none,
    );
    final frequency = Frequency.values.firstWhere(
      (e) => e.name == map['frequency'],
      orElse: () => Frequency.none,
    );
    final intercourse = (map['intercourse'] as bool?) ?? false;

    final explicitFromMap = map['isVdrsExplicit'] as bool?;
    final isExplicit =
        explicitFromMap ??
        (bleeding != Bleeding.none ||
            stretch != Stretch.none ||
            colors.isNotEmpty ||
            consistencies.isNotEmpty ||
            sensation != Sensation.dry ||
            frequency != Frequency.none ||
            intercourse);

    return Observation(
      id: map['id'] ?? '',
      timestamp: _parseTimestamp(map['timestamp']),
      sensation: sensation,
      stretch: stretch,
      colors: colors,
      consistencies: consistencies,
      bleeding: bleeding,
      bleedingColor: map['bleedingColor'] ?? '',
      frequency: frequency,
      intercourse: intercourse,
      painLevel: (map['painLevel'] as num?)?.toDouble() ?? 0.0,
      painTypes: List<String>.from(map['painTypes'] ?? []),
      comment: map['comment'] ?? '',
      userId: map['userId'] ?? '',
      isVdrsExplicit: isExplicit,
    );
  }
}
