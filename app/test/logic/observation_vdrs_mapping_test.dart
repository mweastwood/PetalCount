import 'package:flutter_test/flutter_test.dart';
import 'package:petal_count/logic/logic.dart';

void main() {
  /// Helper factory for creating concise observation instances in tests
  Observation obs({
    Sensation sensation = Sensation.dry,
    Stretch stretch = Stretch.none,
    List<MucusColor> colors = const [],
    List<Consistency> consistencies = const [],
    Bleeding bleeding = Bleeding.none,
    String bleedingColor = '',
    bool? isVdrsExplicit = true,
  }) {
    return Observation(
      id: 'test_obs',
      timestamp: DateTime(2026, 8, 2),
      sensation: sensation,
      stretch: stretch,
      colors: colors,
      consistencies: consistencies,
      bleeding: bleeding,
      bleedingColor: bleedingColor,
      userId: 'test_user',
      isVdrsExplicit: isVdrsExplicit,
    );
  }

  group('1. Dry & Sensation-Only Observations (No Mucus, No Bleeding)', () {
    test('Dry sensation maps to "0"', () {
      expect(obs(sensation: Sensation.dry).vdrsCode, '0');
    });

    test('Damp sensation without mucus maps to "2"', () {
      expect(obs(sensation: Sensation.damp).vdrsCode, '2');
    });

    test('Wet sensation without mucus maps to "2W"', () {
      expect(obs(sensation: Sensation.wet).vdrsCode, '2W');
    });

    test('Shiny sensation without mucus maps to "4"', () {
      expect(obs(sensation: Sensation.shiny).vdrsCode, '4');
    });
  });

  group('2. Mucus Stretch & Color Combinations (Non-Lubricative)', () {
    test('Sticky, Cloudy maps to "6C"', () {
      final item = obs(stretch: Stretch.sticky, colors: [MucusColor.cloudy]);
      expect(item.vdrsCode, '6C');
    });

    test('Sticky, Clear maps to "6K"', () {
      final item = obs(stretch: Stretch.sticky, colors: [MucusColor.clear]);
      expect(item.vdrsCode, '6K');
    });

    test('Sticky, Yellow maps to "6Y"', () {
      final item = obs(stretch: Stretch.sticky, colors: [MucusColor.yellow]);
      expect(item.vdrsCode, '6Y');
    });

    test('Tacky, Cloudy maps to "8C"', () {
      final item = obs(stretch: Stretch.tacky, colors: [MucusColor.cloudy]);
      expect(item.vdrsCode, '8C');
    });

    test('Tacky, Clear maps to "8K"', () {
      final item = obs(stretch: Stretch.tacky, colors: [MucusColor.clear]);
      expect(item.vdrsCode, '8K');
    });

    test('Tacky, Yellow maps to "8Y"', () {
      final item = obs(stretch: Stretch.tacky, colors: [MucusColor.yellow]);
      expect(item.vdrsCode, '8Y');
    });

    test('Stretchy, Clear maps to "10K"', () {
      final item = obs(stretch: Stretch.stretchy, colors: [MucusColor.clear]);
      expect(item.vdrsCode, '10K');
    });

    test('Stretchy, Cloudy maps to "10C"', () {
      final item = obs(stretch: Stretch.stretchy, colors: [MucusColor.cloudy]);
      expect(item.vdrsCode, '10C');
    });

    test('Stretchy, Yellow maps to "10Y"', () {
      final item = obs(stretch: Stretch.stretchy, colors: [MucusColor.yellow]);
      expect(item.vdrsCode, '10Y');
    });

    test('Stretchy, Multiple colors (Cloudy and Clear) maps to "10C/K"', () {
      final item = obs(
        stretch: Stretch.stretchy,
        colors: [MucusColor.cloudy, MucusColor.clear],
      );
      expect(item.vdrsCode, '10C/K');
    });

    test('Mucus with unspecified color defaults to Cloudy "6C"', () {
      final item = obs(stretch: Stretch.sticky, colors: []);
      expect(item.vdrsCode, '6C');
    });
  });

  group('3. Mucus Consistencies (Gummy, Pasty)', () {
    test('Pasty mucus maps strictly to "6CP"', () {
      final item = obs(
        stretch: Stretch.sticky,
        colors: [MucusColor.cloudy],
        consistencies: [Consistency.pasty],
      );
      expect(item.vdrsCode, '6CP');
    });

    test('Gummy mucus maps strictly to "6CG"', () {
      final item = obs(
        stretch: Stretch.sticky,
        colors: [MucusColor.cloudy],
        consistencies: [Consistency.gummy],
      );
      expect(item.vdrsCode, '6CG');
    });

    test('Gummy and Pasty mucus maps to "6CGP"', () {
      final item = obs(
        stretch: Stretch.sticky,
        colors: [MucusColor.cloudy],
        consistencies: [Consistency.gummy, Consistency.pasty],
      );
      expect(item.vdrsCode, '6CGP');
    });
  });

  group('4. Lubricative Mucus & Sensation Codes (10DLK, 10SLK, 10WLK)', () {
    test('Stretchy, Damp, Clear, Lubricative maps to "10DLK"', () {
      final item = obs(
        sensation: Sensation.damp,
        stretch: Stretch.stretchy,
        colors: [MucusColor.clear],
        consistencies: [Consistency.lubricative],
      );
      expect(item.vdrsCode, '10DLK');
    });

    test('Stretchy, Shiny, Clear, Lubricative maps to "10SLK"', () {
      final item = obs(
        sensation: Sensation.shiny,
        stretch: Stretch.stretchy,
        colors: [MucusColor.clear],
        consistencies: [Consistency.lubricative],
      );
      expect(item.vdrsCode, '10SLK');
    });

    test('Stretchy, Wet, Clear, Lubricative maps to "10WLK"', () {
      final item = obs(
        sensation: Sensation.wet,
        stretch: Stretch.stretchy,
        colors: [MucusColor.clear],
        consistencies: [Consistency.lubricative],
      );
      expect(item.vdrsCode, '10WLK');
    });

    test('Stretchy, Wet, Cloudy, Lubricative maps to "10WLC"', () {
      final item = obs(
        sensation: Sensation.wet,
        stretch: Stretch.stretchy,
        colors: [MucusColor.cloudy],
        consistencies: [Consistency.lubricative],
      );
      expect(item.vdrsCode, '10WLC');
    });

    test('Tacky, Wet, Cloudy, Lubricative upgrades to "10WLC"', () {
      final item = obs(
        sensation: Sensation.wet,
        stretch: Stretch.tacky,
        colors: [MucusColor.cloudy],
        consistencies: [Consistency.lubricative],
      );
      expect(item.vdrsCode, '10WLC');
    });

    test(
      'Wet, Lubricative without stretch maps to "10WL" and is Peak-type',
      () {
        final item = obs(
          sensation: Sensation.wet,
          stretch: Stretch.none,
          consistencies: [Consistency.lubricative],
        );
        expect(item.vdrsCode, '10WL');
        expect(item.hasMucus, isTrue);
        expect(item.isPeakType, isTrue);
      },
    );

    test(
      'Damp, Lubricative without stretch maps to "10DL" and is Peak-type',
      () {
        final item = obs(
          sensation: Sensation.damp,
          stretch: Stretch.none,
          consistencies: [Consistency.lubricative],
        );
        expect(item.vdrsCode, '10DL');
        expect(item.hasMucus, isTrue);
        expect(item.isPeakType, isTrue);
      },
    );

    test(
      'Shiny, Lubricative without stretch maps to "10SL" and is Peak-type',
      () {
        final item = obs(
          sensation: Sensation.shiny,
          stretch: Stretch.none,
          consistencies: [Consistency.lubricative],
        );
        expect(item.vdrsCode, '10SL');
        expect(item.hasMucus, isTrue);
        expect(item.isPeakType, isTrue);
      },
    );

    test('Dry, Lubricative without stretch maps to "10L" and is Peak-type', () {
      final item = obs(
        sensation: Sensation.dry,
        stretch: Stretch.none,
        consistencies: [Consistency.lubricative],
      );
      expect(item.vdrsCode, '10L');
      expect(item.hasMucus, isTrue);
      expect(item.isPeakType, isTrue);
    });

    test(
      'Wet, Clear, Lubricative without stretch maps to "10WLK" and is Peak-type',
      () {
        final item = obs(
          sensation: Sensation.wet,
          stretch: Stretch.none,
          colors: [MucusColor.clear],
          consistencies: [Consistency.lubricative],
        );
        expect(item.vdrsCode, '10WLK');
        expect(item.hasMucus, isTrue);
        expect(item.isPeakType, isTrue);
      },
    );
  });

  group('5. Bleeding Observations', () {
    test('Heavy Red bleeding maps to "H"', () {
      final item = obs(bleeding: Bleeding.heavy, bleedingColor: 'R');
      expect(item.vdrsCode, 'H');
    });

    test('Moderate Red bleeding maps to "M"', () {
      final item = obs(bleeding: Bleeding.moderate, bleedingColor: 'R');
      expect(item.vdrsCode, 'M');
    });

    test('Light Red bleeding maps to "L"', () {
      final item = obs(bleeding: Bleeding.light, bleedingColor: 'R');
      expect(item.vdrsCode, 'L');
    });

    test('Very Light Red bleeding maps to "VL"', () {
      final item = obs(bleeding: Bleeding.veryLight, bleedingColor: 'R');
      expect(item.vdrsCode, 'VL');
    });

    test('Spotting Red bleeding maps to "VL"', () {
      final item = obs(bleeding: Bleeding.spotting, bleedingColor: 'R');
      expect(item.vdrsCode, 'VL');
    });

    test('Spotting Brown bleeding maps to "VL-B"', () {
      final item = obs(bleeding: Bleeding.spotting, bleedingColor: 'B');
      expect(item.vdrsCode, 'VL-B');
    });

    test('Brown bleeding maps to "B-B"', () {
      final item = obs(bleeding: Bleeding.brown, bleedingColor: 'B');
      expect(item.vdrsCode, 'B-B');
    });
  });

  group('6. Combined Bleeding + Mucus Observations', () {
    test('Light Red bleeding + Stretchy Clear Mucus maps to "L 10K"', () {
      final item = obs(
        bleeding: Bleeding.light,
        bleedingColor: 'R',
        stretch: Stretch.stretchy,
        colors: [MucusColor.clear],
      );
      expect(item.vdrsCode, 'L 10K');
    });

    test('Spotting Red bleeding + Sticky Cloudy Mucus maps to "VL 6C"', () {
      final item = obs(
        bleeding: Bleeding.spotting,
        bleedingColor: 'R',
        stretch: Stretch.sticky,
        colors: [MucusColor.cloudy],
      );
      expect(item.vdrsCode, 'VL 6C');
    });

    test('Spotting Brown bleeding + Tacky Yellow Mucus maps to "VL-B 8Y"', () {
      final item = obs(
        bleeding: Bleeding.spotting,
        bleedingColor: 'B',
        stretch: Stretch.tacky,
        colors: [MucusColor.yellow],
      );
      expect(item.vdrsCode, 'VL-B 8Y');
    });
  });

  group('7. Non-Explicit VDRS Observations', () {
    test('Non-explicit VDRS observation returns empty string', () {
      final item = obs(
        sensation: Sensation.dry,
        stretch: Stretch.none,
        colors: [],
        consistencies: [],
        bleeding: Bleeding.none,
        isVdrsExplicit: false,
      );
      expect(item.vdrsCode, '');
    });
  });

  group('8. Frequency Codes (x1, x2, x3, AD)', () {
    test('Dry sensation with All Day frequency maps to "0 AD"', () {
      final item = Observation(
        id: 'test',
        timestamp: DateTime(2026, 8, 2),
        sensation: Sensation.dry,
        stretch: Stretch.none,
        colors: const [],
        consistencies: const [],
        bleeding: Bleeding.none,
        frequency: Frequency.allDay,
        userId: 'test_user',
      );
      expect(item.vdrsCode, '0 AD');
    });

    test('Stretchy Clear with Once frequency maps to "10K x1"', () {
      final item = Observation(
        id: 'test',
        timestamp: DateTime(2026, 8, 2),
        sensation: Sensation.dry,
        stretch: Stretch.stretchy,
        colors: const [MucusColor.clear],
        consistencies: const [],
        bleeding: Bleeding.none,
        frequency: Frequency.once,
        userId: 'test_user',
      );
      expect(item.vdrsCode, '10K x1');
    });

    test('Tacky Clear with Twice frequency maps to "8K x2"', () {
      final item = Observation(
        id: 'test',
        timestamp: DateTime(2026, 8, 2),
        sensation: Sensation.dry,
        stretch: Stretch.tacky,
        colors: const [MucusColor.clear],
        consistencies: const [],
        bleeding: Bleeding.none,
        frequency: Frequency.twice,
        userId: 'test_user',
      );
      expect(item.vdrsCode, '8K x2');
    });

    test('Sticky Cloudy with Three times frequency maps to "6C x3"', () {
      final item = Observation(
        id: 'test',
        timestamp: DateTime(2026, 8, 2),
        sensation: Sensation.dry,
        stretch: Stretch.sticky,
        colors: const [MucusColor.cloudy],
        consistencies: const [],
        bleeding: Bleeding.none,
        frequency: Frequency.thrice,
        userId: 'test_user',
      );
      expect(item.vdrsCode, '6C x3');
    });

    test('Very Light bleeding with Dry All Day maps to "VL 0 AD"', () {
      final item = Observation(
        id: 'test',
        timestamp: DateTime(2026, 8, 2),
        sensation: Sensation.dry,
        stretch: Stretch.none,
        colors: const [],
        consistencies: const [],
        bleeding: Bleeding.veryLight,
        frequency: Frequency.allDay,
        userId: 'test_user',
      );
      expect(item.vdrsCode, 'VL 0 AD');
    });

    test('Light bleeding with Sticky Cloudy Once maps to "L 6C x1"', () {
      final item = Observation(
        id: 'test',
        timestamp: DateTime(2026, 8, 2),
        sensation: Sensation.dry,
        stretch: Stretch.sticky,
        colors: const [MucusColor.cloudy],
        consistencies: const [],
        bleeding: Bleeding.light,
        frequency: Frequency.once,
        userId: 'test_user',
      );
      expect(item.vdrsCode, 'L 6C x1');
    });
  });

  group('9. Intercourse Markers (I)', () {
    test('Dry All Day with Intercourse maps to "0 AD I"', () {
      final item = Observation(
        id: 'test',
        timestamp: DateTime(2026, 8, 2),
        sensation: Sensation.dry,
        stretch: Stretch.none,
        colors: const [],
        consistencies: const [],
        bleeding: Bleeding.none,
        frequency: Frequency.allDay,
        intercourse: true,
        userId: 'test_user',
      );
      expect(item.vdrsCode, '0 AD I');
    });

    test('Sticky Cloudy Three times with Intercourse maps to "6C x3 I"', () {
      final item = Observation(
        id: 'test',
        timestamp: DateTime(2026, 8, 2),
        sensation: Sensation.dry,
        stretch: Stretch.sticky,
        colors: const [MucusColor.cloudy],
        consistencies: const [],
        bleeding: Bleeding.none,
        frequency: Frequency.thrice,
        intercourse: true,
        userId: 'test_user',
      );
      expect(item.vdrsCode, '6C x3 I');
    });

    test('Light Bleeding Dry All Day with Intercourse maps to "L 0 AD I"', () {
      final item = Observation(
        id: 'test',
        timestamp: DateTime(2026, 8, 2),
        sensation: Sensation.dry,
        stretch: Stretch.none,
        colors: const [],
        consistencies: const [],
        bleeding: Bleeding.light,
        frequency: Frequency.allDay,
        intercourse: true,
        userId: 'test_user',
      );
      expect(item.vdrsCode, 'L 0 AD I');
    });

    test('Heavy bleeding with Intercourse maps to "H I"', () {
      final item = Observation(
        id: 'test',
        timestamp: DateTime(2026, 8, 2),
        sensation: Sensation.dry,
        stretch: Stretch.none,
        colors: const [],
        consistencies: const [],
        bleeding: Bleeding.heavy,
        intercourse: true,
        userId: 'test_user',
      );
      expect(item.vdrsCode, 'H I');
    });
  });

  group(
    '10. Non-stretch mucus observations (Pasty, Gummy, Colors with stretch == Stretch.none)',
    () {
      test(
        'Pasty consistency with Stretch.none maps to "6CP" and hasMucus == true',
        () {
          final item = obs(
            stretch: Stretch.none,
            consistencies: [Consistency.pasty],
          );
          expect(item.hasMucus, isTrue);
          expect(item.vdrsCode, '6CP');
          expect(item.isPeakType, isFalse);
        },
      );

      test(
        'Gummy consistency with Stretch.none maps to "6CG" and hasMucus == true',
        () {
          final item = obs(
            stretch: Stretch.none,
            consistencies: [Consistency.gummy],
          );
          expect(item.hasMucus, isTrue);
          expect(item.vdrsCode, '6CG');
          expect(item.isPeakType, isFalse);
        },
      );

      test(
        'Gummy and Pasty consistency with Stretch.none maps to "6CGP" and hasMucus == true',
        () {
          final item = obs(
            stretch: Stretch.none,
            consistencies: [Consistency.gummy, Consistency.pasty],
          );
          expect(item.hasMucus, isTrue);
          expect(item.vdrsCode, '6CGP');
          expect(item.isPeakType, isFalse);
        },
      );

      test(
        'Clear mucus color with Stretch.none maps to "0K", hasMucus == true, and isPeakType == true',
        () {
          final item = obs(stretch: Stretch.none, colors: [MucusColor.clear]);
          expect(item.hasMucus, isTrue);
          expect(item.vdrsCode, '0K');
          expect(item.isPeakType, isTrue);
        },
      );

      test(
        'Cloudy mucus color with Stretch.none maps to "0C", hasMucus == true, and isPeakType == false',
        () {
          final item = obs(stretch: Stretch.none, colors: [MucusColor.cloudy]);
          expect(item.hasMucus, isTrue);
          expect(item.vdrsCode, '0C');
          expect(item.isPeakType, isFalse);
        },
      );

      test(
        'Yellow mucus color with Stretch.none maps to "0Y", hasMucus == true, and isPeakType == false',
        () {
          final item = obs(stretch: Stretch.none, colors: [MucusColor.yellow]);
          expect(item.hasMucus, isTrue);
          expect(item.vdrsCode, '0Y');
          expect(item.isPeakType, isFalse);
        },
      );
    },
  );
}
