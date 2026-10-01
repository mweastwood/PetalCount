/// Defines the SVG asset path and raw template for the swaddled sleeping baby icon.
class BabySvg {
  /// Relative asset path for the SVG file.
  static const String assetPath = 'assets/images/baby_swaddled.svg';

  /// Raw SVG template with a configurable stroke color.
  static String getSvg({String strokeColor = '#2E7D32'}) {
    return '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64" width="64" height="64">
  <g fill="none" stroke="$strokeColor" stroke-width="2.8" stroke-linecap="round" stroke-linejoin="round">
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
  }
}
