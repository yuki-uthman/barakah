import 'dart:ui';

/// A positioned, rounded gold box (unit / ten / hour block or fuse piece).
class BlockBox {
  const BlockBox({
    required this.rect,
    required this.radius,
    this.opacity = 1,
    this.solidLight = false,
    this.glowBlur = 0,
    this.glowSpread = 0,
    this.glowAlpha = 0,
  });

  final Rect rect;
  final double radius;
  final double opacity;

  /// True: flat `#FAFAD1` fill; false: the gold gradient.
  final bool solidLight;
  final double glowBlur;
  final double glowSpread;
  final double glowAlpha;
}

class Spark {
  const Spark(this.center, this.size, this.color, this.opacity);
  final Offset center;
  final double size;
  final Color color;
  final double opacity;
}

class Ripple {
  const Ripple(this.center, this.rx, this.ry, this.color, this.opacity);
  final Offset center;
  final double rx;
  final double ry;
  final Color color;
  final double opacity;
}

class Stain {
  const Stain(this.rect, this.opacity);
  final Rect rect;
  final double opacity;
}

class Seep {
  const Seep(this.x, this.height, this.opacity);
  final double x;
  final double height;
  final double opacity;
}

/// Everything the painter needs for one frame (the artifact's `renderVals()`).
class MergeFrame {
  const MergeFrame({
    required this.cellX,
    required this.cellFill,
    required this.cellLine,
    required this.cellOpacity,
    required this.cellGlowBlur,
    required this.cellGlowSpread,
    required this.cellGlowAlpha,
    required this.flyer,
    required this.stream,
    required this.streamDashOffset,
    required this.ripples,
    required this.sparks,
    required this.stains,
    required this.seeps,
    required this.flashRect,
    required this.flashOpacity,
    required this.floodFill,
    required this.floodLine,
    required this.floodSurface,
    required this.clockText,
    required this.totalText,
    required this.status,
    required this.hint,
    required this.cellAria,
    required this.hours,
    required this.tens,
    required this.mins,
    required this.fx,
  });

  final double cellX;
  final Path cellFill;
  final Path cellLine;
  final double cellOpacity;
  final double cellGlowBlur;
  final double cellGlowSpread;
  final double cellGlowAlpha;

  /// The cell shrinking on its way to a unit slot; null when not flying.
  final BlockBox? flyer;

  final Path stream;
  final double streamDashOffset;
  final List<Ripple> ripples;
  final List<Spark> sparks;
  final List<Stain> stains;
  final List<Seep> seeps;
  final Rect flashRect;
  final double flashOpacity;

  final Path floodFill;
  final Path floodLine;
  final double floodSurface;
  final String clockText;
  final String totalText;

  final String status;
  final String hint;
  final String cellAria;

  final List<BlockBox> hours;
  final List<BlockBox> tens;
  final List<BlockBox> mins;
  final List<BlockBox> fx;
}
