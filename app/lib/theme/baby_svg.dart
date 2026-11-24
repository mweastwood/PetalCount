/// Seasonal and holiday Easter egg variants for the swaddled baby icon.
enum BabyVariant {
  classic,
  newYear,
  valentines,
  stPatricks,
  easter,
  july4,
  halloween,
  thanksgiving,
  christmas,
}

/// Defines the SVG asset path and raw templates for the swaddled sleeping baby icon.
///
/// ## Synchronization Strategy
/// The canonical vector artwork is tracked at [assetPath] (`assets/images/baby_swaddled.svg`).
/// For high-performance rendering without bundle loading latency or asset resolution
/// dependencies in headless environments (such as `PdfExportService` via `pw.SvgImage` and
/// fast widget testing without mock asset bundles), [BabySvg.getSvg] provides an inline XML
/// representation.
///
/// When updating the swaddled baby design, ensure modifications to `assets/images/baby_swaddled.svg`
/// are kept in sync with [BabySvg.getSvg]. This synchronization is verified by unit tests.
class BabySvg {
  /// Relative repository path for the source SVG vector file.
  static const String assetPath = 'assets/images/baby_swaddled.svg';

  /// Canonical raw SVG template with the default Creighton theme green stroke (`#2E7D32`).
  static const String rawSvg =
      '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64" width="64" height="64">
  <g fill="none" stroke="#2E7D32" stroke-width="2.8" stroke-linecap="round" stroke-linejoin="round">
    <!-- Hair curl -->
    <path d="M 32 10.5 C 32.5 7.5, 36.5 7, 35.5 10 C 35 11.5, 33 12, 32 13" />
    <!-- Head outline -->
    <path d="M 22 23 C 19.5 15, 25.5 11, 32 11 C 38.5 11, 44.5 15, 42 23" />
    <!-- Sleeping Eyes -->
    <path d="M 25 19.5 Q 28 22 31 19.5" stroke-width="2.4" />
    <path d="M 33 19.5 Q 36 22 39 19.5" stroke-width="2.4" />
    <!-- Little smile -->
    <path d="M 30.5 25 Q 32 26.5 33.5 25" stroke-width="2" />
    <!-- Swaddle Wrap Outer Cocoon -->
    <path d="M 18.5 25 C 13.5 33, 14.5 48.5, 22.5 56 C 27 60, 37 60, 41.5 56 C 49.5 48.5, 50.5 33, 45.5 25" />
    <!-- Swaddle Collar / Wrap V-lines -->
    <path d="M 19.5 25.5 C 23.5 31.5, 31.5 36.5, 43 29" />
    <path d="M 44.5 26.5 C 40.5 33, 31.5 39.5, 20 33.5" />
    <!-- Blanket fold curve -->
    <path d="M 21 41.5 C 27 47, 37 47, 43 41.5" stroke-width="2.4" />
  </g>
</svg>''';

  static const String _newYearSvg =
      '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64" width="64" height="64">
  <g fill="none" stroke="#2E7D32" stroke-width="2.8" stroke-linecap="round" stroke-linejoin="round">
    <!-- Party hat cone & stripes -->
    <path d="M 23.5 14.5 L 32 4 L 40.5 14.5" />
    <path d="M 22.5 15 Q 32 13 41.5 15" />
    <path d="M 27 10.5 L 36.5 9.5" stroke-width="2" />
    <!-- Pom-pom at peak -->
    <circle cx="32" cy="3.5" r="1.8" fill="#2E7D32" stroke="none" />
    <!-- Sparkles -->
    <path d="M 14 10 L 14 14 M 12 12 L 16 12" stroke-width="2" />
    <path d="M 50 10 L 50 14 M 48 12 L 52 12" stroke-width="2" />
    <!-- Head sides & sleeping face -->
    <path d="M 22 23 C 21.2 20, 21.5 17.5, 22.5 15.5" />
    <path d="M 41.5 15.5 C 42.5 17.5, 42.8 20, 42 23" />
    <path d="M 25 19.5 Q 28 22 31 19.5" stroke-width="2.4" />
    <path d="M 33 19.5 Q 36 22 39 19.5" stroke-width="2.4" />
    <path d="M 30.5 25 Q 32 26.5 33.5 25" stroke-width="2" />
    <!-- Swaddle -->
    <path d="M 18.5 25 C 13.5 33, 14.5 48.5, 22.5 56 C 27 60, 37 60, 41.5 56 C 49.5 48.5, 50.5 33, 45.5 25" />
    <path d="M 19.5 25.5 C 23.5 31.5, 31.5 36.5, 43 29" />
    <path d="M 44.5 26.5 C 40.5 33, 31.5 39.5, 20 33.5" />
    <path d="M 21 41.5 C 27 47, 37 47, 43 41.5" stroke-width="2.4" />
  </g>
</svg>''';

  static const String _valentinesSvg =
      '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64" width="64" height="64">
  <g fill="none" stroke="#2E7D32" stroke-width="2.8" stroke-linecap="round" stroke-linejoin="round">
    <path d="M 32 10.5 C 32.5 7.5, 36.5 7, 35.5 10 C 35 11.5, 33 12, 32 13" />
    <path d="M 22 23 C 19.5 15, 25.5 11, 32 11 C 38.5 11, 44.5 15, 42 23" />
    <path d="M 25 19.5 Q 28 22 31 19.5" stroke-width="2.4" />
    <path d="M 33 19.5 Q 36 22 39 19.5" stroke-width="2.4" />
    <path d="M 30.5 25 Q 32 26.5 33.5 25" stroke-width="2" />
    <path d="M 18.5 25 C 13.5 33, 14.5 48.5, 22.5 56 C 27 60, 37 60, 41.5 56 C 49.5 48.5, 50.5 33, 45.5 25" />
    <path d="M 19.5 25.5 C 23.5 30, 40.5 30, 44.5 25.5" />
    <!-- Heart on swaddle -->
    <path d="M 32 49 C 24 43, 23 35.5, 28 35.5 C 30.5 35.5, 32 37.5, 32 39 C 32 37.5, 33.5 35.5, 36 35.5 C 41 35.5, 40 43, 32 49 Z" stroke-width="2.4" />
  </g>
</svg>''';

  static const String _stPatricksSvg =
      '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64" width="64" height="64">
  <g fill="none" stroke="#2E7D32" stroke-width="2.8" stroke-linecap="round" stroke-linejoin="round">
    <!-- Top hat -->
    <path d="M 24.5 14 L 26 6.5 L 38 6.5 L 39.5 14" />
    <path d="M 25.5 11.5 L 38.5 11.5" stroke-width="2" />
    <path d="M 19.5 15 Q 32 13 44.5 15" />
    <!-- Head & face -->
    <path d="M 22 23 C 21.2 20, 21.5 17.5, 22.5 15.5" />
    <path d="M 41.5 15.5 C 42.5 17.5, 42.8 20, 42 23" />
    <path d="M 25 19.5 Q 28 22 31 19.5" stroke-width="2.4" />
    <path d="M 33 19.5 Q 36 22 39 19.5" stroke-width="2.4" />
    <path d="M 30.5 25 Q 32 26.5 33.5 25" stroke-width="2" />
    <!-- Swaddle + 3-leaf shamrock -->
    <path d="M 18.5 25 C 13.5 33, 14.5 48.5, 22.5 56 C 27 60, 37 60, 41.5 56 C 49.5 48.5, 50.5 33, 45.5 25" />
    <path d="M 19.5 25.5 C 23.5 30, 40.5 30, 44.5 25.5" />
    <circle cx="32" cy="38.5" r="2.6" stroke-width="2.1" />
    <circle cx="28.8" cy="43" r="2.6" stroke-width="2.1" />
    <circle cx="35.2" cy="43" r="2.6" stroke-width="2.1" />
    <path d="M 32 44.5 C 32 48, 33.5 50, 35 51" stroke-width="2.1" />
  </g>
</svg>''';

  static const String _easterSvg =
      '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64" width="64" height="64">
  <g fill="none" stroke="#2E7D32" stroke-width="2.8" stroke-linecap="round" stroke-linejoin="round">
    <!-- Sunrise rays -->
    <path d="M 32 4.5 L 32 7.5" stroke-width="2.2" />
    <path d="M 22 7.5 L 24 10" stroke-width="2.2" />
    <path d="M 42 7.5 L 40 10" stroke-width="2.2" />
    <!-- Head & face -->
    <path d="M 22 23 C 19.5 15, 25.5 11, 32 11 C 38.5 11, 44.5 15, 42 23" />
    <path d="M 25 19.5 Q 28 22 31 19.5" stroke-width="2.4" />
    <path d="M 33 19.5 Q 36 22 39 19.5" stroke-width="2.4" />
    <path d="M 30.5 25 Q 32 26.5 33.5 25" stroke-width="2" />
    <!-- Swaddle + Christian Cross -->
    <path d="M 18.5 25 C 13.5 33, 14.5 48.5, 22.5 56 C 27 60, 37 60, 41.5 56 C 49.5 48.5, 50.5 33, 45.5 25" />
    <path d="M 19.5 25.5 C 23.5 30, 40.5 30, 44.5 25.5" />
    <path d="M 32 34.5 L 32 52.5" stroke-width="2.8" />
    <path d="M 25.5 40.5 L 38.5 40.5" stroke-width="2.8" />
  </g>
</svg>''';

  static const String _july4Svg =
      '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64" width="64" height="64">
  <g fill="none" stroke="#2E7D32" stroke-width="2.8" stroke-linecap="round" stroke-linejoin="round">
    <!-- Sparkles -->
    <path d="M 14 11 L 14 15 M 12 13 L 16 13" stroke-width="2" />
    <path d="M 50 11 L 50 15 M 48 13 L 52 13" stroke-width="2" />
    <!-- Head & face -->
    <path d="M 32 10.5 C 32.5 7.5, 36.5 7, 35.5 10 C 35 11.5, 33 12, 32 13" />
    <path d="M 22 23 C 19.5 15, 25.5 11, 32 11 C 38.5 11, 44.5 15, 42 23" />
    <path d="M 25 19.5 Q 28 22 31 19.5" stroke-width="2.4" />
    <path d="M 33 19.5 Q 36 22 39 19.5" stroke-width="2.4" />
    <path d="M 30.5 25 Q 32 26.5 33.5 25" stroke-width="2" />
    <!-- Swaddle + Star -->
    <path d="M 18.5 25 C 13.5 33, 14.5 48.5, 22.5 56 C 27 60, 37 60, 41.5 56 C 49.5 48.5, 50.5 33, 45.5 25" />
    <path d="M 19.5 25.5 C 23.5 30, 40.5 30, 44.5 25.5" />
    <polygon points="32,34.5 34.1,39.5 39.5,39.8 35.3,43.2 36.7,48.5 32,45.5 27.3,48.5 28.7,43.2 24.5,39.8 29.9,39.5" stroke-width="2.2" />
  </g>
</svg>''';

  static const String _halloweenSvg =
      '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64" width="64" height="64">
  <g fill="none" stroke="#2E7D32" stroke-width="2.8" stroke-linecap="round" stroke-linejoin="round">
    <!-- Witch hat -->
    <path d="M 23.5 14 L 31.5 4.5 L 36.5 7.5 L 40.5 14" />
    <path d="M 15.5 15.5 Q 32 12.5 48.5 15.5" />
    <!-- Head & face -->
    <path d="M 22 23 C 21.2 20, 21.5 17.5, 22.5 15.5" />
    <path d="M 41.5 15.5 C 42.5 17.5, 42.8 20, 42 23" />
    <path d="M 25 19.5 Q 28 22 31 19.5" stroke-width="2.4" />
    <path d="M 33 19.5 Q 36 22 39 19.5" stroke-width="2.4" />
    <path d="M 30.5 25 Q 32 26.5 33.5 25" stroke-width="2" />
    <!-- Swaddle -->
    <path d="M 18.5 25 C 13.5 33, 14.5 48.5, 22.5 56 C 27 60, 37 60, 41.5 56 C 49.5 48.5, 50.5 33, 45.5 25" />
    <path d="M 19.5 25.5 C 23.5 31.5, 31.5 36.5, 43 29" />
    <path d="M 44.5 26.5 C 40.5 33, 31.5 39.5, 20 33.5" />
    <path d="M 21 41.5 C 27 47, 37 47, 43 41.5" stroke-width="2.4" />
  </g>
</svg>''';

  static const String _thanksgivingSvg =
      '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64" width="64" height="64">
  <g fill="none" stroke="#2E7D32" stroke-width="2.8" stroke-linecap="round" stroke-linejoin="round">
    <!-- Pumpkin stem & curled vine -->
    <path d="M 31 11 C 31 7.5, 34 6, 35 8.5" />
    <path d="M 34.5 8.5 C 37 7.5, 39 9.5, 37.5 11.5" stroke-width="2.2" />
    <!-- Head & face -->
    <path d="M 22 23 C 19.5 15, 25.5 11, 32 11 C 38.5 11, 44.5 15, 42 23" />
    <path d="M 25 19.5 Q 28 22 31 19.5" stroke-width="2.4" />
    <path d="M 33 19.5 Q 36 22 39 19.5" stroke-width="2.4" />
    <path d="M 30.5 25 Q 32 26.5 33.5 25" stroke-width="2" />
    <!-- Pumpkin-ribbed Swaddle -->
    <path d="M 18.5 25 C 12 34, 13.5 49, 22.5 56 C 27 59.5, 37 59.5, 41.5 56 C 50.5 49, 52 34, 45.5 25" />
    <path d="M 19.5 25.5 C 24 31, 40 31, 44.5 25.5" />
    <path d="M 26.5 31 C 23.5 40, 24.5 51, 28 57.5" stroke-width="2.2" />
    <path d="M 37.5 31 C 40.5 40, 39.5 51, 36 57.5" stroke-width="2.2" />
    <path d="M 32 31 L 32 58.5" stroke-width="2.2" />
  </g>
</svg>''';

  static const String _christmasSvg =
      '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64" width="64" height="64">
  <g fill="none" stroke="#2E7D32" stroke-width="2.8" stroke-linecap="round" stroke-linejoin="round">
    <!-- Fluffy Santa hat cuff -->
    <path d="M 21 15.5 C 18.5 15.5, 18.5 11.5, 21.5 11.5 L 42.5 11.5 C 45.5 11.5, 45.5 15.5, 43 15.5 Z" stroke-width="2.4" />
    <!-- Sweeping floppy Santa cone -->
    <path d="M 22 11.5 C 23.5 4.5, 34 2.5, 43 7.5 C 46 9.2, 47.5 10.5, 48.5 12" />
    <!-- Dangling pom-pom -->
    <circle cx="50.5" cy="14" r="2.8" stroke-width="2.4" />
    <!-- Head sides & sleeping face -->
    <path d="M 22 23 C 21.2 20.5, 21.4 18, 22 16" />
    <path d="M 42 16 C 42.6 18, 42.8 20.5, 42 23" />
    <path d="M 25 19.5 Q 28 22 31 19.5" stroke-width="2.4" />
    <path d="M 33 19.5 Q 36 22 39 19.5" stroke-width="2.4" />
    <path d="M 30.5 25 Q 32 26.5 33.5 25" stroke-width="2" />
    <!-- Swaddle -->
    <path d="M 18.5 25 C 13.5 33, 14.5 48.5, 22.5 56 C 27 60, 37 60, 41.5 56 C 49.5 48.5, 50.5 33, 45.5 25" />
    <path d="M 19.5 25.5 C 23.5 31.5, 31.5 36.5, 43 29" />
    <path d="M 44.5 26.5 C 40.5 33, 31.5 39.5, 20 33.5" />
    <path d="M 21 41.5 C 27 47, 37 47, 43 41.5" stroke-width="2.4" />
  </g>
</svg>''';

  /// Resolves the rare holiday Easter egg [BabyVariant] for [date], or
  /// [BabyVariant.classic] on all other dates.
  ///
  /// - New Year's Eve & New Year's Day: Dec 31 and Jan 1
  /// - Valentine's Day: Feb 14
  /// - St. Patrick's Day: Mar 17
  /// - Easter: Easter Sunday (Gregorian computus)
  /// - July 4th: Jul 4
  /// - Halloween: Oct 31
  /// - Thanksgiving: 4th Thursday of November
  /// - Christmas: Dec 25
  static BabyVariant variantForDate(DateTime date) {
    final month = date.month;
    final day = date.day;

    if ((month == 12 && day == 31) || (month == 1 && day == 1)) {
      return BabyVariant.newYear;
    }
    if (month == 2 && day == 14) {
      return BabyVariant.valentines;
    }
    if (month == 3 && day == 17) {
      return BabyVariant.stPatricks;
    }
    if (_isEasterSunday(date)) {
      return BabyVariant.easter;
    }
    if (month == 7 && day == 4) {
      return BabyVariant.july4;
    }
    if (month == 10 && day == 31) {
      return BabyVariant.halloween;
    }
    if (month == 11 &&
        date.weekday == DateTime.thursday &&
        day >= 22 &&
        day <= 28) {
      return BabyVariant.thanksgiving;
    }
    if (month == 12 && day == 25) {
      return BabyVariant.christmas;
    }
    return BabyVariant.classic;
  }

  /// Anonymous Gregorian algorithm for Western Easter Sunday.
  static bool _isEasterSunday(DateTime date) {
    if (date.month != 3 && date.month != 4) return false;
    final y = date.year;
    final a = y % 19;
    final b = y ~/ 100;
    final c = y % 100;
    final d = b ~/ 4;
    final e = b % 4;
    final f = (b + 8) ~/ 25;
    final g = (b - f + 1) ~/ 3;
    final h = (19 * a + b - d - g + 15) % 30;
    final i = c ~/ 4;
    final k = c % 4;
    final l = (32 + 2 * e + 2 * i - h - k) % 7;
    final m = (a + 11 * h + 22 * l) ~/ 451;
    final easterMonth = (h + l - 7 * m + 114) ~/ 31;
    final easterDay = ((h + l - 7 * m + 114) % 31) + 1;
    return date.month == easterMonth && date.day == easterDay;
  }

  static String _templateFor(BabyVariant variant) {
    switch (variant) {
      case BabyVariant.classic:
        return rawSvg;
      case BabyVariant.newYear:
        return _newYearSvg;
      case BabyVariant.valentines:
        return _valentinesSvg;
      case BabyVariant.stPatricks:
        return _stPatricksSvg;
      case BabyVariant.easter:
        return _easterSvg;
      case BabyVariant.july4:
        return _july4Svg;
      case BabyVariant.halloween:
        return _halloweenSvg;
      case BabyVariant.thanksgiving:
        return _thanksgivingSvg;
      case BabyVariant.christmas:
        return _christmasSvg;
    }
  }

  /// Raw SVG template with a configurable stroke color and optional [variant].
  ///
  /// In Flutter UI widgets (e.g. `BabyIcon`), color tinting is applied via `ColorFilter`
  /// shader on the template to utilize Flutter's compiled picture cache and
  /// preserve alpha transparency. In PDF export (`PdfExportService`), the [strokeColor]
  /// parameter is supplied directly to interpolate the hex color.
  static String getSvg({
    String strokeColor = '#2E7D32',
    BabyVariant variant = BabyVariant.classic,
  }) {
    final template = _templateFor(variant);
    if (strokeColor == '#2E7D32') {
      return template;
    }
    final isUnhashedHex = RegExp(r'^[0-9a-fA-F]{3,8}$').hasMatch(strokeColor);
    final normalizedColor = isUnhashedHex ? '#$strokeColor' : strokeColor;
    return template.replaceAll('#2E7D32', normalizedColor);
  }
}
