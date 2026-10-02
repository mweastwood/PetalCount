import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/baby_svg.dart';
import '../theme/creighton_theme.dart';

/// Renders a cute swaddled sleeping baby vector SVG icon for Creighton stamps.
class BabyIcon extends StatelessWidget {
  final double size;
  final Color? color;
  final String? semanticsLabel;

  const BabyIcon({
    super.key,
    this.size = 24.0,
    this.color,
    this.semanticsLabel = 'Baby icon',
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? CreightonTheme.babyIconGreen;

    return SvgPicture.string(
      BabySvg.getSvg(),
      width: size,
      height: size,
      fit: BoxFit.contain,
      semanticsLabel: semanticsLabel,
      colorFilter: ColorFilter.mode(effectiveColor, BlendMode.srcIn),
    );
  }
}
