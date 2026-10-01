import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/baby_svg.dart';
import '../theme/creighton_theme.dart';

/// Renders a cute swaddled sleeping baby vector SVG icon for Creighton stamps.
class BabyIcon extends StatelessWidget {
  final double size;
  final Color? color;

  const BabyIcon({
    super.key,
    this.size = 24.0,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? CreightonTheme.babyIconGreen;
    final hex =
        '#${(effectiveColor.toARGB32() & 0x00FFFFFF).toRadixString(16).padLeft(6, '0')}';

    return SvgPicture.string(
      BabySvg.getSvg(strokeColor: hex),
      width: size,
      height: size,
      fit: BoxFit.contain,
    );
  }
}
