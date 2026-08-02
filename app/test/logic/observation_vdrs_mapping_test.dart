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
    test('Sticky, Cloudy maps to "6-C"', () {
      final item = obs(stretch: Stretch.sticky, colors: [MucusColor.cloudy]);
      expect(item.vdrsCode, '6-C');
    });

    test('Sticky, Clear maps to "6-K"', () {
      final item = obs(stretch: Stretch.sticky, colors: [MucusColor.clear]);
      expect(item.vdrsCode, '6-K');
    });

    test('Sticky, Yellow maps to "6-Y"', () {
      final item = obs(stretch: Stretch.sticky, colors: [MucusColor.yellow]);
      expect(item.vdrsCode, '6-Y');
    });

    test('Sticky, White maps to "6-W"', () {
      final item = obs(stretch: Stretch.sticky, colors: [MucusColor.white]);
      expect(item.vdrsCode, '6-W');
    });

    test('Tacky, Cloudy maps to "8-C"', () {
      final item = obs(stretch: Stretch.tacky, colors: [MucusColor.cloudy]);
      expect(item.vdrsCode, '8-C');
    });

    test('Tacky, Clear maps to "8-K"', () {
      final item = obs(stretch: Stretch.tacky, colors: [MucusColor.clear]);
      expect(item.vdrsCode, '8-K');
    });

    test('Tacky, Yellow maps to "8-Y"', () {
      final item = obs(stretch: Stretch.tacky, colors: [MucusColor.yellow]);
      expect(item.vdrsCode, '8-Y');
    });

    test('Stretchy, Clear maps to "10-K"', () {
      final item = obs(stretch: Stretch.stretchy, colors: [MucusColor.clear]);
      expect(item.vdrsCode, '10-K');
    });

    test('Stretchy, Cloudy maps to "10-C"', () {
      final item = obs(stretch: Stretch.stretchy, colors: [MucusColor.cloudy]);
      expect(item.vdrsCode, '10-C');
    });

    test('Stretchy, Yellow maps to "10-Y"', () {
      final item = obs(stretch: Stretch.stretchy, colors: [MucusColor.yellow]);
      expect(item.vdrsCode, '10-Y');
    });

    test('Stretchy, Multiple colors (Cloudy and Clear) maps to "10-C/K"', () {
      final item = obs(
        stretch: Stretch.stretchy,
        colors: [MucusColor.cloudy, MucusColor.clear],
      );
      expect(item.vdrsCode, '10-C/K');
    });

    test('Mucus with unspecified color defaults to Cloudy "6-C"', () {
      final item = obs(stretch: Stretch.sticky, colors: []);
      expect(item.vdrsCode, '6-C');
    });
  });

  group('3. Mucus Consistencies (Gummy, Pasty)', () {
    test('Sticky, Cloudy, Gummy maps to "6-C-G"', () {
      final item = obs(
        stretch: Stretch.sticky,
        colors: [MucusColor.cloudy],
        consistencies: [Consistency.gummy],
      );
      expect(item.vdrsCode, '6-C-G');
    });

    test('Tacky, White, Pasty maps to "8-W-P"', () {
      final item = obs(
        stretch: Stretch.tacky,
        colors: [MucusColor.white],
        consistencies: [Consistency.pasty],
      );
      expect(item.vdrsCode, '8-W-P');
    });

    test('Stretchy, Cloudy, Gummy maps to "10-C-G"', () {
      final item = obs(
        stretch: Stretch.stretchy,
        colors: [MucusColor.cloudy],
        consistencies: [Consistency.gummy],
      );
      expect(item.vdrsCode, '10-C-G');
    });

    test('Stretchy, Clear, Pasty maps to "10-K-P"', () {
      final item = obs(
        stretch: Stretch.stretchy,
        colors: [MucusColor.clear],
        consistencies: [Consistency.pasty],
      );
      expect(item.vdrsCode, '10-K-P');
    });
  });

  group('4. Lubricative Mucus & Sensation Codes (10DL, 10SL, 10WL)', () {
    test('Stretchy, Damp, Clear, Lubricative maps to "10DL-K"', () {
      final item = obs(
        sensation: Sensation.damp,
        stretch: Stretch.stretchy,
        colors: [MucusColor.clear],
        consistencies: [Consistency.lubricative],
      );
      expect(item.vdrsCode, '10DL-K');
    });

    test('Stretchy, Shiny, Clear, Lubricative maps to "10SL-K"', () {
      final item = obs(
        sensation: Sensation.shiny,
        stretch: Stretch.stretchy,
        colors: [MucusColor.clear],
        consistencies: [Consistency.lubricative],
      );
      expect(item.vdrsCode, '10SL-K');
    });

    test('Stretchy, Wet, Clear, Lubricative maps to "10WL-K"', () {
      final item = obs(
        sensation: Sensation.wet,
        stretch: Stretch.stretchy,
        colors: [MucusColor.clear],
        consistencies: [Consistency.lubricative],
      );
      expect(item.vdrsCode, '10WL-K');
    });

    test('Stretchy, Wet, Cloudy, Lubricative maps to "10WL-C"', () {
      final item = obs(
        sensation: Sensation.wet,
        stretch: Stretch.stretchy,
        colors: [MucusColor.cloudy],
        consistencies: [Consistency.lubricative],
      );
      expect(item.vdrsCode, '10WL-C');
    });
  });

  group('5. Bleeding Observations', () {
    test('Heavy Red bleeding maps to "H-R"', () {
      final item = obs(bleeding: Bleeding.heavy, bleedingColor: 'R');
      expect(item.vdrsCode, 'H-R');
    });

    test('Moderate Red bleeding maps to "M-R"', () {
      final item = obs(bleeding: Bleeding.moderate, bleedingColor: 'R');
      expect(item.vdrsCode, 'M-R');
    });

    test('Light Red bleeding maps to "L-R"', () {
      final item = obs(bleeding: Bleeding.light, bleedingColor: 'R');
      expect(item.vdrsCode, 'L-R');
    });

    test('Very Light Red bleeding maps to "VL-R"', () {
      final item = obs(bleeding: Bleeding.veryLight, bleedingColor: 'R');
      expect(item.vdrsCode, 'VL-R');
    });

    test('Spotting Red bleeding maps to "S-R"', () {
      final item = obs(bleeding: Bleeding.spotting, bleedingColor: 'R');
      expect(item.vdrsCode, 'S-R');
    });

    test('Spotting Brown bleeding maps to "S-B"', () {
      final item = obs(bleeding: Bleeding.spotting, bleedingColor: 'B');
      expect(item.vdrsCode, 'S-B');
    });

    test('Brown bleeding maps to "B-B"', () {
      final item = obs(bleeding: Bleeding.brown, bleedingColor: 'B');
      expect(item.vdrsCode, 'B-B');
    });
  });

  group('6. Combined Bleeding + Mucus Observations', () {
    test('Light Red bleeding + Stretchy Clear Mucus maps to "L-R 10-K"', () {
      final item = obs(
        bleeding: Bleeding.light,
        bleedingColor: 'R',
        stretch: Stretch.stretchy,
        colors: [MucusColor.clear],
      );
      expect(item.vdrsCode, 'L-R 10-K');
    });

    test('Spotting Red bleeding + Sticky Cloudy Mucus maps to "S-R 6-C"', () {
      final item = obs(
        bleeding: Bleeding.spotting,
        bleedingColor: 'R',
        stretch: Stretch.sticky,
        colors: [MucusColor.cloudy],
      );
      expect(item.vdrsCode, 'S-R 6-C');
    });

    test('Spotting Brown bleeding + Tacky Yellow Mucus maps to "S-B 8-Y"', () {
      final item = obs(
        bleeding: Bleeding.spotting,
        bleedingColor: 'B',
        stretch: Stretch.tacky,
        colors: [MucusColor.yellow],
      );
      expect(item.vdrsCode, 'S-B 8-Y');
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
}
