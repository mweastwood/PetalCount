import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/baby_svg.dart';
import '../theme/creighton_theme.dart';

/// Renders a cute swaddled sleeping baby vector SVG icon for Creighton stamps,
/// with rare holiday Easter egg variants on specific dates.
class BabyIcon extends StatelessWidget {
  final double size;
  final Color? color;
  final String? semanticsLabel;
  final bool excludeFromSemantics;
  final DateTime? date;
  final BabyVariant? variant;

  const BabyIcon({
    super.key,
    this.size = 24.0,
    this.color,
    this.semanticsLabel = 'Baby icon',
    this.excludeFromSemantics = false,
    this.date,
    this.variant,
  });

  /// Creates a [BabyIcon] with color automatically resolved from the Creighton [stampType].
  factory BabyIcon.forStamp(
    StampType? stampType, {
    Key? key,
    double size = 24.0,
    String? semanticsLabel = 'Baby icon',
    bool excludeFromSemantics = false,
    DateTime? date,
    BabyVariant? variant,
  }) {
    return BabyIcon(
      key: key,
      size: size,
      color: CreightonTheme.getBabyIconColor(stampType),
      semanticsLabel: semanticsLabel,
      excludeFromSemantics: excludeFromSemantics,
      date: date,
      variant: variant,
    );
  }

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? CreightonTheme.babyIconGreen;
    final effectiveVariant =
        variant ??
        (date != null ? BabySvg.variantForDate(date!) : BabyVariant.classic);

    return SvgPicture.string(
      BabySvg.getSvg(variant: effectiveVariant),
      width: size,
      height: size,
      fit: BoxFit.contain,
      semanticsLabel: excludeFromSemantics ? null : semanticsLabel,
      excludeFromSemantics: excludeFromSemantics,
      colorFilter: ColorFilter.mode(effectiveColor, BlendMode.srcIn),
    );
  }
}
