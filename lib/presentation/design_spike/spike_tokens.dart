import 'package:flutter/animation.dart';
import 'package:flutter/painting.dart';

/// Every literal value from `docs/design/spike-artifact/Main.dc.html` lives in
/// this file. Names follow the role the value plays in the artifact.

abstract final class SpikeColors {
  static const Color screenBase = Color(0xFF0C1710);
  static const Color screenTop = Color(0xFF18291D);
  // Radial glow at the top; "transparent" keeps the gold hue so the Flutter
  // (non-premultiplied) lerp matches CSS premultiplied interpolation.
  static const Color topGlow = Color.fromRGBO(228, 200, 125, 0.14);
  static const Color topGlowEnd = Color.fromRGBO(228, 200, 125, 0);

  static const Color gold = Color(0xFFE4C87D);
  static const Color goldLight = Color(0xFFFAFAD1);
  static const Color cream = Color(0xFFF1EAD6);
  static const Color muted = Color(0xFF93A694);

  static const Color floodFill = Color(0xFFB0935A);
  static const Color floodLabelDark = Color(0xFF4E3D18);
  static const Color floodClockDark = Color(0xFF1A1206);

  static const Color shieldFill = Color.fromRGBO(241, 234, 214, 0.035);
  static const Color shieldStroke = Color.fromRGBO(241, 234, 214, 0.72);

  static const Color groundLine = Color.fromRGBO(241, 234, 214, 0.22);
  static const Color groundShadowTop = Color.fromRGBO(0, 0, 0, 0.28);
  static const Color groundShadowEnd = Color.fromRGBO(0, 0, 0, 0);

  static const Color stain = Color.fromRGBO(92, 104, 94, 1); // alpha per blob
  static const Color seep = Color.fromRGBO(150, 158, 146, 1); // alpha per seep
  static const Color splashRest = Color.fromRGBO(112, 122, 110, 1);

  static const Color cellBackground = Color.fromRGBO(0, 0, 0, 0.5);
  static const Color cellInnerBorder = Color.fromRGBO(255, 255, 255, 0.18);
  static const Color glowRgb = Color.fromRGBO(228, 200, 125, 1);

  static const Color navBorder = Color.fromRGBO(228, 200, 125, 0.60);
  static const Color navFill = Color.fromRGBO(12, 23, 16, 0.70);
}

abstract final class SpikeFonts {
  static const String display = 'CormorantGaramond';
  static const String body = 'EBGaramond';

  static List<FontVariation> wght(double w) => [FontVariation('wght', w)];
}

abstract final class SpikeText {
  /// 15px, tracking 3px, uppercase, 600 — "Left of today", "Caught today".
  static const TextStyle label = TextStyle(
    fontFamily: SpikeFonts.display,
    fontSize: 15,
    letterSpacing: 3,
    fontWeight: FontWeight.w600,
    fontVariations: [FontVariation('wght', 600)],
    color: SpikeColors.gold,
  );

  /// 46px / line-height 50 / 600 — countdown clock.
  static const TextStyle clock = TextStyle(
    fontFamily: SpikeFonts.display,
    fontSize: 46,
    height: 50 / 46,
    leadingDistribution: TextLeadingDistribution.even,
    fontWeight: FontWeight.w600,
    fontVariations: [FontVariation('wght', 600)],
    fontFeatures: [FontFeature.tabularFigures()],
    color: SpikeColors.cream,
  );

  /// 52px / line-height 1.05 / 500 — "caught" total.
  static const TextStyle total = TextStyle(
    fontFamily: SpikeFonts.display,
    fontSize: 52,
    height: 1.05,
    leadingDistribution: TextLeadingDistribution.even,
    fontWeight: FontWeight.w500,
    fontVariations: [FontVariation('wght', 500)],
    fontFeatures: [FontFeature.tabularFigures()],
    color: SpikeColors.cream,
  );

  /// 16px EB Garamond muted — hint and status lines.
  static const TextStyle body = TextStyle(
    fontFamily: SpikeFonts.body,
    fontSize: 16,
    fontFeatures: [FontFeature.tabularFigures()],
    color: SpikeColors.muted,
  );
}

abstract final class SpikeMetrics {
  static const double width = 390;
  static const double height = 844;
  static const double centerX = 195;

  // Countdown shield (box 390x240).
  static const double shieldHeight = 240;
  static const double shieldStrokeWidth = 3.5;
  static const double shieldTextTop = 74;
  static const double shieldTextGap = 2;
  static const double clockDigitW = 25;
  static const double clockColonW = 13;
  static const double floodLineWidth = 1.5;
  static const double floodTop = 10; // bisection bounds (shield top / bottom)
  static const double floodBottom = 236;
  static const double floodWaveAmp = 3;
  static const double floodWaveRate = 0.8;
  static const int floodBisectSteps = 22;

  // Ground.
  static const double groundY = 452;
  static const double groundInset = 24;
  static const double groundShadowTop = 453;
  static const double groundShadowHeight = 70;

  // Cell.
  static const double cellSize = 120;
  static const double cellTop = 330;
  static const double cellRadius = 28;
  static const double cellRunX = centerX - cellSize / 2;
  static const double cellIdleX = cellRunX + 96;
  static const double cellWaveLineWidth = 1.5;
  static const double cellPressScale = 0.97;

  // Stream.
  static const double streamTop = 238;
  static const double streamStep = 10;
  static const double streamWidth = 6; // prop streamWidth default
  static const double groundSplash = 1.2; // prop groundSplash default
  static const double streamGlowOpacity = 0.16;
  static const double streamCoreOpacity = 0.95;
  static const double rippleStroke = 1.2;

  // Unit blocks.
  static const double unitSize = 14;
  static const double unitRadius = 3;
  static const double unitGridX = 111.5;
  static const double unitPitch = 17;
  static const double unitY = 592;
  static const double tenSize = 30;
  static const double tenRadius = 7;
  static const double tenY = 552;
  static const double hourSize = 52;
  static const double hourRadius = 12;
  static const double hourY = 530;
  static const double tenPitch = 35; // 30 + 5 gap
  static const double hourPitch = 58; // 52 + 6 gap

  // Text rows.
  static const double hintTop = 474;
  static const double caughtLabelTop = 496;
  static const double totalTop = 620;
  static const double totalDigitW = 28;
  static const double totalColonW = 15;

  // Nav.
  static const double navInset = 20;
  static const double navBottom = 28;
  static const double navButton = 60;
  static const double navIcon = 26;
  static const double navIconStroke = 1.6; // in a 24 viewBox
}

abstract final class SpikeMotion {
  /// CSS `ease` = cubic-bezier(.25,.1,.25,1). Flutter ships it as
  /// [Curves.ease], the identical curve.
  static const Curve cssEase = Curves.ease;

  /// Block slide transition: `transition: left 450ms ease`.
  static const Duration blockSlide = Duration(milliseconds: 450);

  /// `.press` transform transition: 180ms ease, scale .97 while pressed.
  static const Duration press = Duration(milliseconds: 180);

  /// Unit cell flying to its slot (`hand.p += dt / 0.8`), smoothstep easing.
  static const double handSeconds = 0.8;

  /// Fuse animation length (variant 'fuse').
  static const double fuseSeconds = 0.8;

  /// Cell slide between idle/run positions: exponential approach, rate 5/s.
  static const double posRate = 5;

  /// Wave-tilt spring.
  static const double tiltStiffness = 90;
  static const double tiltDamping = 9;
  static const double tiltGain = 3.4;
  static const double tiltMax = 13;

  /// Undo ("under a minute · let go") drain rate.
  static const double undoRate = 2.5;

  static const double maxDt = 0.1;
  static const double gravity = 430;
  static const double sparkLife = 0.78;
  static const double catchSparkLife = 0.55;

  /// Artifact prop `demoSpeed` default: 1 (one second of app time per second).
  static const double demoSpeed = 1;
}
