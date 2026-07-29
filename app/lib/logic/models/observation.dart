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
  white('W', 'White');

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
  spotting('S', 'Spotting'),
  brown('B', 'Brown bleeding'),
  red('R', 'Red bleeding');

  final String code;
  final String label;
  const Bleeding(this.code, this.label);
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
  final double painLevel; // 0.0 to 10.0
  final List<String> painTypes; // e.g., ['Cramps', 'Ovulation Pain']
  final String comment;
  final String userId;

  Observation({
    required this.id,
    required this.timestamp,
    required this.sensation,
    required this.stretch,
    required this.colors,
    required this.consistencies,
    required this.bleeding,
    this.bleedingColor = '',
    this.painLevel = 0.0,
    this.painTypes = const [],
    this.comment = '',
    required this.userId,
  });

  bool get hasMucus => stretch != Stretch.none;
  bool get hasBleeding => bleeding != Bleeding.none;

  // Generates the standard VDRS code for this specific observation
  String get vdrsCode {
    if (hasBleeding) {
      final bCode = bleeding.code;
      final colorSuffix = bleedingColor.isNotEmpty ? '-$bleedingColor' : '';
      final bleedingPart = '$bCode$colorSuffix';

      if (!hasMucus) {
        return bleedingPart;
      } else {
        // Combined bleeding and mucus (e.g. "L-R 10-K-L")
        return '$bleedingPart ${mucusPart()}';
      }
    } else {
      return mucusPart();
    }
  }

  String mucusPart() {
    if (!hasMucus) {
      // Just sensation
      return sensation.code;
    }

    // Mucus format: [Stretch]-[Color]-[Consistency]
    // If lubricative, sensation can also be added as 10-DL, 10-SL, 10-WL
    final stretchCode = stretch.code;

    // Color string (e.g. "C/K" or "C" or "Y")
    final colorStr = colors.isEmpty
        ? 'C' // Default to cloudy if none specified but mucus exists
        : colors.map((c) => c.code).join('/');

    // Consistency string (e.g. "G" or "L")
    final consistencyStr = consistencies.map((c) => c.code).join('');

    // If it contains Lubricative, check the sensation to form 10DL, 10SL, 10WL
    final containsL = consistencies.contains(Consistency.lubricative);
    if (containsL && stretch == Stretch.stretchy) {
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

      final suffix = otherConsistencies.isNotEmpty
          ? '-$otherConsistencies'
          : '';
      return '$lubricativeCode-$colorStr$suffix';
    }

    final consistencyPart = consistencyStr.isNotEmpty ? '-$consistencyStr' : '';
    return '$stretchCode-$colorStr$consistencyPart';
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
      'painLevel': painLevel,
      'painTypes': painTypes,
      'comment': comment,
      'userId': userId,
    };
  }

  factory Observation.fromMap(Map<String, dynamic> map) {
    return Observation(
      id: map['id'] ?? '',
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      sensation: Sensation.values.firstWhere(
        (e) => e.name == map['sensation'],
        orElse: () => Sensation.dry,
      ),
      stretch: Stretch.values.firstWhere(
        (e) => e.name == map['stretch'],
        orElse: () => Stretch.none,
      ),
      colors: ((map['colors'] as List?) ?? [])
          .map((item) => MucusColor.values.firstWhere((e) => e.name == item))
          .toList(),
      consistencies: ((map['consistencies'] as List?) ?? [])
          .map((item) => Consistency.values.firstWhere((e) => e.name == item))
          .toList(),
      bleeding: Bleeding.values.firstWhere(
        (e) => e.name == map['bleeding'],
        orElse: () => Bleeding.none,
      ),
      bleedingColor: map['bleedingColor'] ?? '',
      painLevel: (map['painLevel'] as num?)?.toDouble() ?? 0.0,
      painTypes: List<String>.from(map['painTypes'] ?? []),
      comment: map['comment'] ?? '',
      userId: map['userId'] ?? '',
    );
  }
}
