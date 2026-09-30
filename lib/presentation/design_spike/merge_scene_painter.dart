import 'dart:math' as math;

import 'package:flutter/rendering.dart';

import 'merge_frame.dart';
import 'spike_tokens.dart';

/// Paints the whole 390x844 "Merge 1 · Gather and fuse" scene (everything
/// except the two nav buttons and the tap target, which are widgets).
class MergeScenePainter extends CustomPainter {
  MergeScenePainter({
    required this.frame,
    required this.pressScale,
    super.repaint,
  });

  /// Re-read on every paint so a controller can swap frames without
  /// rebuilding the widget tree.
  final MergeFrame Function() frame;
  final double Function() pressScale;

  static final Path _shield = Path()
    ..moveTo(56, 10)
    ..lineTo(334, 10)
    ..arcToPoint(const Offset(378, 54), radius: const Radius.circular(44))
    ..lineTo(378, 118)
    ..cubicTo(378, 196, 286, 236, 195, 236)
    ..cubicTo(104, 236, 12, 196, 12, 118)
    ..lineTo(12, 54)
    ..arcToPoint(const Offset(56, 10), radius: const Radius.circular(44))
    ..close();

  @override
  void paint(Canvas canvas, Size size) {
    final f = frame();
    _background(canvas);
    _shieldClock(canvas, f);
    _ground(canvas);
    _splash(canvas, f);
    _cell(canvas, f);
    _stream(canvas, f);
    if (f.flyer != null) _block(canvas, f.flyer!);
    _centered(canvas, f.hint, SpikeText.body, SpikeMetrics.hintTop);
    _centered(
      canvas,
      'CAUGHT TODAY',
      SpikeText.label,
      SpikeMetrics.caughtLabelTop,
    );
    for (final b in f.hours) {
      _block(canvas, b);
    }
    for (final b in f.tens) {
      _block(canvas, b);
    }
    for (final b in f.mins) {
      _block(canvas, b);
    }
    for (final b in f.fx) {
      _block(canvas, b);
    }
    final rowH = _fixedRow(
      canvas,
      f.totalText,
      SpikeText.total,
      SpikeMetrics.totalDigitW,
      SpikeMetrics.totalColonW,
      SpikeMetrics.totalTop,
    );
    _centered(
      canvas,
      f.status,
      SpikeText.body,
      SpikeMetrics.totalTop + rowH + 2,
    );
  }

  // ---- background ----

  void _background(Canvas canvas) {
    const r = Rect.fromLTWH(0, 0, SpikeMetrics.width, SpikeMetrics.height);
    canvas.drawRect(
      r,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [SpikeColors.screenTop, SpikeColors.screenBase],
        ).createShader(r),
    );
    // radial-gradient(430px 520px at 50% -90px, glow 0%, transparent 70%)
    canvas.save();
    canvas.translate(SpikeMetrics.centerX, -90);
    canvas.scale(430, 520);
    canvas.drawRect(
      Rect.fromLTRB(
        -SpikeMetrics.centerX / 430,
        90 / 520,
        (SpikeMetrics.width - SpikeMetrics.centerX) / 430,
        (SpikeMetrics.height + 90) / 520,
      ),
      Paint()
        ..shader = const RadialGradient(
          radius: 1,
          colors: [SpikeColors.topGlow, SpikeColors.topGlowEnd],
          stops: [0, 0.7],
        ).createShader(const Rect.fromLTRB(-1, -1, 1, 1)),
    );
    canvas.restore();
  }

  // ---- countdown shield ----

  void _shieldClock(Canvas canvas, MergeFrame f) {
    _shieldText(canvas, f.clockText, SpikeColors.gold, SpikeColors.cream);
    canvas.save();
    canvas.clipPath(_shield);
    canvas.drawPath(f.floodFill, Paint()..color = SpikeColors.floodFill);
    canvas.drawPath(
      f.floodLine,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = SpikeMetrics.floodLineWidth
        ..color = SpikeColors.goldLight,
    );
    canvas.save();
    canvas.clipRect(
      Rect.fromLTRB(
        0,
        f.floodSurface,
        SpikeMetrics.width,
        SpikeMetrics.shieldHeight + 1000,
      ),
    );
    _shieldText(
      canvas,
      f.clockText,
      SpikeColors.floodLabelDark,
      SpikeColors.floodClockDark,
    );
    canvas.restore();
    canvas.restore();
    canvas.drawPath(_shield, Paint()..color = SpikeColors.shieldFill);
    canvas.drawPath(
      _shield,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = SpikeMetrics.shieldStrokeWidth
        ..strokeJoin = StrokeJoin.round
        ..color = SpikeColors.shieldStroke,
    );
  }

  void _shieldText(Canvas canvas, String clock, Color label, Color digits) {
    final lp = _layout('LEFT OF TODAY', SpikeText.label.copyWith(color: label));
    lp.paint(
      canvas,
      Offset(SpikeMetrics.centerX - lp.width / 2, SpikeMetrics.shieldTextTop),
    );
    _fixedRow(
      canvas,
      clock,
      SpikeText.clock.copyWith(color: digits),
      SpikeMetrics.clockDigitW,
      SpikeMetrics.clockColonW,
      SpikeMetrics.shieldTextTop + lp.height + SpikeMetrics.shieldTextGap,
    );
  }

  // ---- ground ----

  void _ground(Canvas canvas) {
    const strip = Rect.fromLTWH(
      0,
      SpikeMetrics.groundShadowTop,
      SpikeMetrics.width,
      SpikeMetrics.groundShadowHeight,
    );
    canvas.drawRect(
      strip,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [SpikeColors.groundShadowTop, SpikeColors.groundShadowEnd],
        ).createShader(strip),
    );
    canvas.drawRect(
      Rect.fromLTWH(
        SpikeMetrics.groundInset,
        SpikeMetrics.groundY,
        SpikeMetrics.width - 2 * SpikeMetrics.groundInset,
        1,
      ),
      Paint()..color = SpikeColors.groundLine,
    );
  }

  void _splash(Canvas canvas, MergeFrame f) {
    for (final s in f.stains) {
      canvas.drawOval(
        s.rect,
        Paint()..color = SpikeColors.stain.withValues(alpha: s.opacity),
      );
    }
    for (final s in f.seeps) {
      final r = Rect.fromLTWH(s.x, SpikeMetrics.groundY + 2, 1.5, s.height);
      canvas.drawRRect(
        RRect.fromRectAndRadius(r, const Radius.circular(1)),
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              SpikeColors.seep.withValues(alpha: s.opacity),
              SpikeColors.seep.withValues(alpha: 0),
            ],
          ).createShader(r),
      );
    }
    // radial-gradient(circle, rgba(250,250,209,.95), transparent 70%) on a
    // square box: farthest-corner radius = half-diagonal.
    final fr = f.flashRect;
    canvas.saveLayer(
      fr.inflate(2),
      Paint()..color = Color.fromRGBO(0, 0, 0, f.flashOpacity),
    );
    canvas.save();
    canvas.clipRRect(
      RRect.fromRectAndRadius(fr, Radius.circular(fr.width / 2)),
    );
    canvas.drawRect(
      fr,
      Paint()
        ..shader = RadialGradient(
          radius: math.sqrt2,
          colors: [
            SpikeColors.goldLight.withValues(alpha: 0.95),
            SpikeColors.goldLight.withValues(alpha: 0),
          ],
          stops: const [0, 0.7],
        ).createShader(fr),
    );
    canvas.restore();
    canvas.restore();
    for (final s in f.sparks) {
      canvas.drawOval(
        Rect.fromCenter(center: s.center, width: s.size, height: s.size),
        Paint()..color = s.color.withValues(alpha: s.opacity),
      );
    }
  }

  // ---- cell ----

  void _cell(Canvas canvas, MergeFrame f) {
    const c = SpikeMetrics.cellSize;
    final rect = Rect.fromLTWH(f.cellX, SpikeMetrics.cellTop, c, c);
    final rr = RRect.fromRectAndRadius(
      rect,
      const Radius.circular(SpikeMetrics.cellRadius),
    );
    canvas.save();
    final s = pressScale();
    canvas.translate(rect.center.dx, rect.center.dy);
    canvas.scale(s, s);
    canvas.translate(-rect.center.dx, -rect.center.dy);
    _glow(
      canvas,
      rr,
      f.cellGlowBlur,
      f.cellGlowSpread,
      SpikeColors.glowRgb.withValues(alpha: f.cellGlowAlpha),
    );
    canvas.drawRRect(rr, Paint()..color = SpikeColors.cellBackground);
    if (f.cellOpacity > 0) {
      canvas.save();
      canvas.clipRRect(rr);
      canvas.translate(f.cellX, SpikeMetrics.cellTop);
      canvas.drawPath(f.cellFill, Paint()..color = SpikeColors.gold);
      canvas.drawPath(
        f.cellLine,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = SpikeMetrics.cellWaveLineWidth
          ..color = SpikeColors.goldLight,
      );
      canvas.restore();
    }
    // inset 0 0 0 1px border
    canvas.drawRRect(
      rr.deflate(0.5),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = SpikeColors.cellInnerBorder,
    );
    canvas.restore();
  }

  // ---- stream ----

  void _stream(Canvas canvas, MergeFrame f) {
    const sw = SpikeMetrics.streamWidth;
    final glow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = sw * 2.6 + 2
      ..color = SpikeColors.gold.withValues(
        alpha: SpikeMetrics.streamGlowOpacity,
      );
    final core = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = sw
      ..color = SpikeColors.gold.withValues(
        alpha: SpikeMetrics.streamCoreOpacity,
      );
    final bead = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = sw * 0.55 + 1.4
      ..color = SpikeColors.goldLight.withValues(
        alpha: SpikeMetrics.streamCoreOpacity,
      );
    canvas.drawPath(f.stream, glow);
    canvas.drawPath(f.stream, core);
    // stroke-dasharray "(3+sw) (59-sw)", dashoffset -d  => dashes start at d.
    const dash = 3 + sw, gap = 59 - sw, period = dash + gap;
    for (final metric in f.stream.computeMetrics()) {
      for (
        var s = f.streamDashOffset - period;
        s < metric.length;
        s += period
      ) {
        final a = math.max(0.0, s), b = math.min(metric.length, s + dash);
        if (b > a) canvas.drawPath(metric.extractPath(a, b), bead);
      }
    }
    for (final r in f.ripples) {
      canvas.drawOval(
        Rect.fromCenter(center: r.center, width: r.rx * 2, height: r.ry * 2),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = SpikeMetrics.rippleStroke
          ..color = r.color.withValues(alpha: r.opacity),
      );
    }
  }

  // ---- blocks ----

  /// linear-gradient(180deg, #FAFAD1 -70%, #E4C87D 70%): the -70% stop is off
  /// the box, so the top edge starts at the 50% mix.
  Paint _goldPaint(Rect r) => Paint()
    ..shader = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color.lerp(SpikeColors.goldLight, SpikeColors.gold, 0.5)!,
        SpikeColors.gold,
        SpikeColors.gold,
      ],
      stops: const [0, 0.7, 1],
    ).createShader(r);

  void _glow(Canvas canvas, RRect rr, double blur, double spread, Color c) {
    canvas.save();
    canvas.clipPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(rr.outerRect.inflate(blur * 3 + spread + 8)),
        Path()..addRRect(rr),
      ),
    );
    canvas.drawRRect(
      rr.inflate(spread),
      Paint()
        ..color = c
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, blur / 2),
    );
    canvas.restore();
  }

  void _block(Canvas canvas, BlockBox b) {
    if (b.opacity <= 0) return;
    final rr = RRect.fromRectAndRadius(b.rect, Radius.circular(b.radius));
    final layered = b.opacity < 1;
    if (layered) {
      canvas.saveLayer(
        b.rect.inflate(b.glowBlur * 3 + b.glowSpread + 8),
        Paint()..color = Color.fromRGBO(0, 0, 0, b.opacity),
      );
    }
    if (b.glowAlpha > 0) {
      _glow(
        canvas,
        rr,
        b.glowBlur,
        b.glowSpread,
        SpikeColors.glowRgb.withValues(alpha: b.glowAlpha),
      );
    }
    canvas.drawRRect(
      rr,
      b.solidLight
          ? (Paint()..color = SpikeColors.goldLight)
          : _goldPaint(b.rect),
    );
    if (layered) canvas.restore();
  }

  // ---- text ----

  static final Map<String, TextPainter> _cache = {};

  static TextPainter _layout(String text, TextStyle style) {
    final key = '$text|${style.fontSize}|${style.color}|${style.fontWeight}';
    return _cache.putIfAbsent(key, () {
      return TextPainter(
        text: TextSpan(text: text, style: style),
        textDirection: TextDirection.ltr,
      )..layout();
    });
  }

  void _centered(Canvas canvas, String text, TextStyle style, double top) {
    final tp = _layout(text, style);
    tp.paint(canvas, Offset(SpikeMetrics.centerX - tp.width / 2, top));
  }

  /// Fixed-width character cells (the artifact's per-char `inline-block`
  /// spans), centred on the screen. Returns the row height.
  double _fixedRow(
    Canvas canvas,
    String text,
    TextStyle style,
    double digitW,
    double colonW,
    double top,
  ) {
    double widthOf(String ch) => ch == ':' ? colonW : digitW;
    final total = text.split('').fold<double>(0, (a, ch) => a + widthOf(ch));
    var x = SpikeMetrics.centerX - total / 2;
    var h = 0.0;
    for (final ch in text.split('')) {
      final tp = _layout(ch, style);
      tp.paint(canvas, Offset(x + (widthOf(ch) - tp.width) / 2, top));
      x += widthOf(ch);
      h = tp.height;
    }
    return h;
  }

  @override
  bool shouldRepaint(covariant MergeScenePainter old) => true;
}
