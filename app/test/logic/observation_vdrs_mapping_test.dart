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
    test('Light Red bleeding + Stretchy Clear Mucus maps to "L-R 10K"', () {
      final item = obs(
        bleeding: Bleeding.light,
        bleedingColor: 'R',
        stretch: Stretch.stretchy,
        colors: [MucusColor.clear],
      );
      expect(item.vdrsCode, 'L-R 10K');
    });

    test('Spotting Red bleeding + Sticky Cloudy Mucus maps to "S-R 6C"', () {
      final item = obs(
        bleeding: Bleeding.spotting,
        bleedingColor: 'R',
        stretch: Stretch.sticky,
        colors: [MucusColor.cloudy],
      );
      expect(item.vdrsCode, 'S-R 6C');
    });

    test('Spotting Brown bleeding + Tacky Yellow Mucus maps to "S-B 8Y"', () {
      final item = obs(
        bleeding: Bleeding.spotting,
        bleedingColor: 'B',
        stretch: Stretch.tacky,
        colors: [MucusColor.yellow],
      );
      expect(item.vdrsCode, 'S-B 8Y');
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
