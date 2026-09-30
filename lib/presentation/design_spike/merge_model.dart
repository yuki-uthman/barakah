import 'dart:math' as math;
import 'dart:ui';

import 'merge_frame.dart';
import 'spike_tokens.dart';

double _clamp01(double v) => v < 0 ? 0 : (v > 1 ? 1 : v);

/// CSS-style smoothstep used all over the artifact script.
double smooth(double p) {
  p = _clamp01(p);
  return p * p * (3 - 2 * p);
}

// Flood-clock silhouette: half-width of the shield per 2px row (artifact `HW`).
const List<double> _shieldHalfWidth = [
  0, 0, 0, 0, 0, 139.0, 152.1, 157.3, 161.2, 164.3, 166.9, 169.2, 171.2, //
  172.9, 174.5, 175.9, 177.1, 178.2, 179.1, 180.0, 180.7, 181.3, 181.8,
  182.3, 182.6, 182.8, 183.0, 183, 183, 183, 183, 183, 183, 183, 183, 183,
  183, 183, 183, 183, 183, 183, 183, 183, 183, 183, 183, 183, 183, 183, 183,
  183, 183, 183, 183, 183, 183, 183.0, 182.9, 182.8, 182.7, 182.5, 182.3,
  181.9, 181.7, 181.3, 180.8, 180.3, 179.9, 179.3, 178.7, 178.0, 177.3,
  176.5, 175.7, 174.8, 173.9, 172.7, 171.7, 170.6, 169.2, 168.1, 166.9,
  165.3, 163.7, 162.4, 160.7, 158.9, 157.0, 155.1, 153.2, 150.8, 148.7,
  146.1, 143.9, 141.2, 138.4, 135.6, 132.7, 129.2, 126.1, 122.5, 118.8,
  115.0, 110.6, 106.0, 100.8, 96.1, 90.1, 84.0, 77.2, 69.5, 60.5, 49.4,
  35.3, 0.0, 0, 0,
];

class _Hand {
  _Hand(this.slot);
  double p = 0;
  final int slot;
}

class _Fuse {
  _Fuse(this.isTen, this.src, this.dst, this.dstSize);
  final bool isTen;
  final List<Offset> src; // top-left of each source piece
  final Offset dst; // top-left of destination
  final double dstSize;
  double p = 0;
  double get srcSize => isTen ? SpikeMetrics.unitSize : SpikeMetrics.tenSize;
}

class _Slide {
  _Slide(this.to) : from = to, start = -1e9;
  double from;
  double to;
  double start;
}

/// Port of the artifact's `_tick` / `_animTick` / `renderVals` logic.
/// Pure Dart; time is fed in, so it is deterministic under test.
class MergeModel {
  MergeModel({
    bool sessionRunning = true,
    this.demoSpeed = SpikeMotion.demoSpeed,
    DateTime Function()? clock,
    this.hoursLeftOverride = 0,
  }) : _clock = clock ?? DateTime.now {
    running = sessionRunning;
    pos = sessionRunning ? 1 : 0;
  }

  final double demoSpeed;
  final double hoursLeftOverride;
  final DateTime Function() _clock;

  bool running = true;
  double pos = 1;
  double frac = 0.2;
  int cells = 47;
  double elapsed = 0;
  _Hand? _hand;
  double t = 0;
  double tilt = 0;
  double _tiltVel = 0;
  double _f0 = 0.2;
  int _c0 = 47;
  bool undo = false;
  int dH = 0, dT = 4, dU = 7;
  _Fuse? _anim;
  String? _since;

  // Splash state carried between frames (`_gs`, `_lt`).
  double? _gs;
  double? _lt;

  final List<_Slide> _hourSlides = [];
  final List<_Slide> _tenSlides = [];

  bool get flying => _hand != null;
  bool get fusing => _anim != null;
  bool get fusingTen => _anim?.isTen ?? false;

  String _hm() {
    final d = _clock();
    return '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  void setRunning(bool on) {
    if (running == on) return;
    running = on;
    if (on) {
      _since = _hm();
      elapsed = 0;
      _f0 = frac;
      _c0 = cells;
      undo = false;
    } else if (elapsed < 60 && _hand == null) {
      undo = true;
      cells = _c0;
    }
  }

  void toggle() => setRunning(!running);

  /// Test/demo helper: jump the partial minute.
  void debugSetFrac(double v) => frac = v;

  void tick(double dt, double time) {
    dt = math.min(SpikeMotion.maxDt, dt);
    final p0 = pos;
    pos += ((running ? 1 : 0) - pos) * math.min(1, dt * SpikeMotion.posRate);
    t = time;
    _animTick(dt);
    final vel = (pos - p0) / math.max(dt, 0.001);
    final want = (vel * SpikeMotion.tiltGain)
        .clamp(-SpikeMotion.tiltMax, SpikeMotion.tiltMax)
        .toDouble();
    _tiltVel +=
        ((want - tilt) * SpikeMotion.tiltStiffness -
            _tiltVel * SpikeMotion.tiltDamping) *
        dt;
    tilt += _tiltVel * dt;
    if (undo) {
      frac += (_f0 - frac) * math.min(1, dt * SpikeMotion.undoRate);
      if ((frac - _f0).abs() < 0.003) {
        frac = _f0;
        undo = false;
      }
    }
    final hand = _hand;
    if (hand != null) {
      hand.p += dt / SpikeMotion.handSeconds;
      if (hand.p >= 1) {
        cells += 1;
        _landed();
        if (cells > 99999) cells = 47;
        _hand = null;
      }
    }
    if (running && pos > 0.9) {
      elapsed += dt * demoSpeed;
      frac += dt * demoSpeed / 60;
      if (frac >= 1 && _hand == null) {
        frac = 0;
        _hand = _Hand(dU % 10);
      }
    }
  }

  // ---- stack bookkeeping (units → tens → hours) ----

  ({List<double> hx, List<double> tx}) _lay(int hn, int tn) {
    const hp = SpikeMetrics.hourPitch, tp = SpikeMetrics.tenPitch;
    final total =
        (hn > 0 ? hn * hp - 6 : 0) +
        (hn > 0 && tn > 0 ? 12 : 0) +
        (tn > 0 ? tn * tp - 5 : 0);
    final x0 = SpikeMetrics.centerX - total / 2;
    final hx = [for (var i = 0; i < hn; i++) x0 + i * hp];
    final ts = x0 + (hn > 0 ? hn * hp - 6 + (tn > 0 ? 12 : 0) : 0);
    final tx = [for (var j = 0; j < tn; j++) ts + j * tp];
    return (hx: hx, tx: tx);
  }

  void _startFuse(bool isTen) {
    if (isTen) {
      final dst = Offset(_lay(dH, dT + 1).tx[dT], SpikeMetrics.tenY);
      _anim = _Fuse(
        true,
        [
          for (var i = 0; i < 10; i++)
            Offset(
              SpikeMetrics.unitGridX + i * SpikeMetrics.unitPitch,
              SpikeMetrics.unitY,
            ),
        ],
        dst,
        SpikeMetrics.tenSize,
      );
    } else {
      final before = _lay(dH, dT);
      final dst = Offset(_lay(dH + 1, dT - 6).hx[dH], SpikeMetrics.hourY);
      _anim = _Fuse(
        false,
        [for (var j = 0; j < 6; j++) Offset(before.tx[j], SpikeMetrics.tenY)],
        dst,
        SpikeMetrics.hourSize,
      );
    }
  }

  void _landed() {
    dU += 1;
    if (cells > 125) {
      cells = 47;
      dH = 0;
      dT = 4;
      dU = 7;
      _anim = null;
    }
  }

  void _animTick(double dt) {
    final a = _anim;
    if (a == null) {
      if (_hand == null && dH * 60 + dT * 10 + dU != cells) {
        dH = cells ~/ 60;
        dT = (cells % 60) ~/ 10;
        dU = cells % 10;
      }
      if (dU >= 10) {
        _startFuse(true);
      } else if (dT >= 6) {
        _startFuse(false);
      }
      return;
    }
    a.p += dt / SpikeMotion.fuseSeconds;
    if (a.p >= 1) {
      if (a.isTen) {
        dU -= 10;
        dT += 1;
      } else {
        dT -= 6;
        dH += 1;
      }
      _anim = null;
    }
  }

  // ---- frame ----

  static String _hms(int s) =>
      '${(s ~/ 3600).toString().padLeft(2, '0')}:${((s % 3600) ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';

  ({Path fill, Path line}) _wave(
    double w,
    double h,
    double f,
    double amp,
    double phase,
    double tiltV,
  ) {
    const n = 28;
    final top = h * (1 - _clamp01(f));
    final pts = <Offset>[];
    for (var i = 0; i <= n; i++) {
      final u = i / n;
      pts.add(
        Offset(
          w * u,
          top -
              tiltV * (2 * u - 1) +
              amp * math.sin(u * 1.35 * 2 * math.pi + phase),
        ),
      );
    }
    final line = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (final p in pts.skip(1)) {
      line.lineTo(p.dx, p.dy);
    }
    final fill = Path()..moveTo(0, h);
    for (final p in pts) {
      fill.lineTo(p.dx, p.dy);
    }
    fill
      ..lineTo(w, h)
      ..close();
    return (fill: fill, line: line);
  }

  static double _rnd(num n) {
    final x = math.sin(n * 12.9898) * 43758.5453;
    return x - x.floorToDouble();
  }

  static Color _mix(double u) => Color.fromRGBO(
    (228 + (112 - 228) * u).round(),
    (200 + (122 - 200) * u).round(),
    (125 + (110 - 125) * u).round(),
    1,
  );

  /// Slide (`transition: left 450ms ease`) for block [i] of [slides].
  double _slid(List<_Slide> slides, int i, double target) {
    while (slides.length <= i) {
      slides.add(_Slide(target));
    }
    final s = slides[i];
    final dur = SpikeMotion.blockSlide.inMicroseconds / 1e6;
    final k = SpikeMotion.cssEase.transform(_clamp01((t - s.start) / dur));
    final cur = s.from + (s.to - s.from) * k;
    if (s.to != target) {
      s.from = cur;
      s.to = target;
      s.start = t;
      return cur;
    }
    return cur;
  }

  BlockBox _unit(
    double x,
    double y,
    double size,
    double radius,
    double blur,
    double alpha, {
    double spread = 0.5,
  }) {
    return BlockBox(
      rect: Rect.fromLTWH(x, y, size, size),
      radius: radius,
      glowBlur: blur,
      glowSpread: spread,
      glowAlpha: alpha,
    );
  }

  MergeFrame frame() {
    const w = SpikeMetrics.cellSize, h = SpikeMetrics.cellSize;
    const top = SpikeMetrics.cellTop,
        runX = SpikeMetrics.cellRunX,
        idleX = SpikeMetrics.cellIdleX;
    const gy = SpikeMetrics.unitY;
    const uh = SpikeMetrics.unitSize;

    double cellX = idleX + (runX - idleX) * smooth(pos);
    double lvX = -200,
        lvY = -200,
        lvW = SpikeMetrics.unitSize,
        lvH = SpikeMetrics.unitSize;
    double lvR = SpikeMetrics.unitRadius, lvO = 0;
    final hand = _hand;
    if (hand != null) {
      final hp = smooth(hand.p);
      final sx = SpikeMetrics.unitGridX + hand.slot * SpikeMetrics.unitPitch;
      final sy = gy;
      final c1x = runX - 80, c1y = sy - 20, q = 1 - hp;
      lvX = q * q * runX + 2 * q * hp * c1x + hp * hp * sx;
      lvY = q * q * top + 2 * q * hp * c1y + hp * hp * sy;
      final sz = smooth(math.min(1, hand.p * 1.6));
      lvW = w + (uh - w) * sz;
      lvH = h + (uh - h) * sz;
      lvR = sz > 0.5 ? SpikeMetrics.unitRadius : SpikeMetrics.cellRadius;
      lvO = 1;
      cellX = idleX + (runX - idleX) * smooth(hand.p / 0.4);
    }

    final surfaceY = top + h * (1 - frac);
    final covers =
        cellX <= SpikeMetrics.centerX - 12 &&
        cellX + w >= SpikeMetrics.centerX + 12;
    double endY = covers ? surfaceY : SpikeMetrics.groundY;
    if (running && !covers) {
      if (hand != null &&
          lvX <= SpikeMetrics.centerX &&
          lvX + lvW >= SpikeMetrics.centerX &&
          lvY < SpikeMetrics.groundY) {
        endY = lvY;
      }
    }
    final catching = endY < 451;
    final calm = 0.12 + 0.88 * (1 - smooth((frac - 0.6) / 0.38));
    final amp = (3.5 + (catching ? 1.4 : 0)) * calm;
    final cellWave = _wave(
      w,
      h,
      frac,
      amp,
      running ? t * 2.2 : 0.6,
      tilt * calm,
    );

    // Stream centre line.
    final stream = Path()..moveTo(SpikeMetrics.centerX, SpikeMetrics.streamTop);
    for (
      var y = SpikeMetrics.streamTop;
      y < endY;
      y += SpikeMetrics.streamStep
    ) {
      stream.lineTo(
        SpikeMetrics.centerX + 1.4 * math.sin(y * 0.035 - t * 3.2),
        y,
      );
    }
    stream.lineTo(SpikeMetrics.centerX, endY);

    // Countdown flood.
    final now = _clock();
    var left = 86400 - (now.hour * 3600 + now.minute * 60 + now.second);
    if (hoursLeftOverride > 0) {
      left = math.min(86400, (hoursLeftOverride * 3600).round());
    }
    final dayF = _clamp01(left / 86400);
    double areaBelow(double yy) {
      var a = 0.0;
      for (var i = 0; i < _shieldHalfWidth.length; i++) {
        final y0 = i * 2;
        if (y0 + 2 <= yy) continue;
        a += _shieldHalfWidth[i] * math.min(2, y0 + 2 - yy);
      }
      return a;
    }

    final tot = areaBelow(0);
    var flo = SpikeMetrics.floodTop, fhi = SpikeMetrics.floodBottom;
    for (var i = 0; i < SpikeMetrics.floodBisectSteps; i++) {
      final mid = (flo + fhi) / 2;
      if (areaBelow(mid) / tot > dayF) {
        flo = mid;
      } else {
        fhi = mid;
      }
    }
    final flood = _wave(
      SpikeMetrics.width,
      SpikeMetrics.shieldHeight,
      1 - flo / SpikeMetrics.shieldHeight,
      SpikeMetrics.floodWaveAmp,
      t * SpikeMetrics.floodWaveRate,
      0,
    );
    final caught = ((cells + (hand != null ? 1 : 0) + frac) * 60).floor();

    // Splash / catch particles.
    const sw = SpikeMetrics.streamWidth, si = SpikeMetrics.groundSplash;
    final vol = math.pow(math.max(1, sw) / 2, 0.75).toDouble();
    final lastT = _lt ?? t;
    _lt = t;
    var gs = _gs ?? (catching ? 0.0 : 1.0);
    gs += ((catching ? 0 : 1) - gs) * math.min(1, math.max(0, t - lastT) * 8);
    _gs = gs;

    final sparks = <Spark>[];
    final stains = <Stain>[];
    final seeps = <Seep>[];
    final np = math.min(44, (11 * si * vol).round());
    const life = SpikeMotion.sparkLife, grav = SpikeMotion.gravity;
    const gyGround = SpikeMetrics.groundY;
    for (var n = 0; n < np; n++) {
      final cyc = t / life + n / np;
      final kk = cyc.floor();
      final u = cyc - kk, tau = u * life, sd = n * 7 + kk * 13;
      final dir = _rnd(sd) < 0.5 ? -1 : 1;
      final vx =
          dir *
          (18 + 62 * _rnd(sd + 1)) *
          (0.8 + 0.3 * si) *
          (0.85 + 0.15 * vol);
      final vy =
          -(95 + 105 * _rnd(sd + 2)) * (0.8 + 0.3 * si) * (0.88 + 0.12 * vol);
      final py = gyGround + vy * tau + 0.5 * grav * tau * tau;
      final sz = (2.2 + 2.2 * _rnd(sd + 3)) * (0.75 + 0.25 * vol);
      if (py > gyGround) continue;
      sparks.add(
        Spark(
          Offset(SpikeMetrics.centerX + vx * tau, py),
          sz,
          _mix(math.min(1, u * 1.5)),
          gs * (1 - u * 0.75),
        ),
      );
    }
    for (var a2 = 0; a2 < 2; a2++) {
      final su = (t / 1.7 + a2 / 2) % 1;
      final sw2 = (34 + 110 * su) * (0.7 + 0.35 * si) * (0.72 + 0.28 * vol);
      final sh = (5 + 8 * su) * (0.8 + 0.2 * vol);
      stains.add(
        Stain(
          Rect.fromLTWH(
            SpikeMetrics.centerX - sw2 / 2,
            gyGround - sh / 2,
            sw2,
            sh,
          ),
          gs * 0.5 * (1 - su),
        ),
      );
    }
    final ns = math.min(14, (6 * vol).round());
    for (var e = 0; e < ns; e++) {
      final eu = (t / 1.3 + _rnd(e + 40)) % 1;
      seeps.add(
        Seep(
          SpikeMetrics.centerX + (_rnd(e + 50) - 0.5) * 84 * (0.8 + 0.2 * vol),
          3 + 13 * eu,
          gs * si * 0.45 * (1 - eu),
        ),
      );
    }
    final cs = (1 - gs) * (endY < 451 ? 1 : 0) * calm;
    final nc = math.min(14, (4 * vol).round());
    const cl = SpikeMotion.catchSparkLife;
    for (var c = 0; c < nc; c++) {
      final cy = t / cl + c / nc;
      final ck = cy.floor();
      final cu = cy - ck, ct = cu * cl, cd = c * 5 + ck * 11;
      final cvx =
          (_rnd(cd) < 0.5 ? -1 : 1) *
          (8 + 30 * _rnd(cd + 1)) *
          (0.8 + 0.2 * vol);
      final cvy = -(48 + 50 * _rnd(cd + 2)) * (0.8 + 0.2 * vol);
      final cpy = endY + cvy * ct + 0.5 * grav * ct * ct;
      final csz = (1.8 + 1.6 * _rnd(cd + 3)) * (0.75 + 0.25 * vol);
      if (cpy > endY || cs < 0.02) continue;
      sparks.add(
        Spark(
          Offset(SpikeMetrics.centerX + cvx * ct, cpy),
          csz,
          SpikeColors.goldLight,
          cs * (1 - cu) * 0.9,
        ),
      );
    }
    final fS = 32 * (0.7 + 0.3 * vol);
    final ripples = <Ripple>[];
    for (var k = 0; k < 3; k++) {
      final p = (t * 0.7 + k / 3) % 1;
      final rx = 4 + (catching ? 34 : 46) * p;
      ripples.add(
        Ripple(
          Offset(SpikeMetrics.centerX, endY),
          catching
              ? rx * (0.9 + 0.1 * vol)
              : rx * (1 + 0.5 * si) * (0.8 + 0.2 * vol),
          rx * (catching ? 0.15 : 0.2),
          catching ? SpikeColors.gold : _mix(math.min(1, p * 1.6)),
          (1 - p) * 0.6,
        ),
      );
    }

    // Stack blocks.
    final a = _anim;
    final isHour = a != null && !a.isTen;
    final isTen = a != null && a.isTen;
    final setT = math.max(0, dT - (isHour ? 6 : 0));
    final lay = _lay(dH + (isHour ? 1 : 0), setT + (isTen ? 1 : 0));
    final setU = math.max(0, dU - (isTen ? 10 : 0));
    final hours = <BlockBox>[], tens = <BlockBox>[], mins = <BlockBox>[];
    for (var i = 0; i < dH; i++) {
      hours.add(
        _unit(
          _slid(_hourSlides, i, lay.hx[i]),
          SpikeMetrics.hourY,
          SpikeMetrics.hourSize,
          SpikeMetrics.hourRadius,
          14,
          0.45,
          spread: 1,
        ),
      );
    }
    if (_hourSlides.length > dH) {
      _hourSlides.removeRange(dH, _hourSlides.length);
    }
    for (var i = 0; i < setT; i++) {
      tens.add(
        _unit(
          _slid(_tenSlides, i, lay.tx[i]),
          SpikeMetrics.tenY,
          SpikeMetrics.tenSize,
          SpikeMetrics.tenRadius,
          9,
          0.42,
        ),
      );
    }
    if (_tenSlides.length > setT) {
      _tenSlides.removeRange(setT, _tenSlides.length);
    }
    for (var i = 0; i < math.min(10, setU); i++) {
      mins.add(
        _unit(
          SpikeMetrics.unitGridX + i * SpikeMetrics.unitPitch,
          SpikeMetrics.unitY,
          SpikeMetrics.unitSize,
          SpikeMetrics.unitRadius,
          5,
          0.38,
        ),
      );
    }

    return MergeFrame(
      cellX: cellX,
      cellFill: cellWave.fill,
      cellLine: cellWave.line,
      cellOpacity: frac > 0.004 ? 1 : 0,
      cellGlowBlur: 12 + 30 * frac,
      cellGlowSpread: 1 + 3 * frac,
      cellGlowAlpha: 0.16 + 0.4 * frac + (catching ? 0.12 : 0),
      flyer: lvO > 0
          ? BlockBox(
              rect: Rect.fromLTWH(lvX, lvY, lvW, lvH),
              radius: lvR,
              opacity: lvO,
              glowBlur: 18,
              glowSpread: 2,
              glowAlpha: 0.55,
            )
          : null,
      stream: stream,
      streamDashOffset: (t * 150) % 62,
      ripples: ripples,
      sparks: sparks,
      stains: stains,
      seeps: seeps,
      flashRect: Rect.fromLTWH(
        SpikeMetrics.centerX - fS / 2,
        gyGround - fS / 2,
        fS,
        fS,
      ),
      flashOpacity: _clamp01(gs * (0.55 + 0.25 * math.sin(t * 9))),
      floodFill: flood.fill,
      floodLine: flood.line,
      floodSurface: flo,
      clockText: _hms(left),
      totalText: _hms(caught),
      status: undo
          ? 'Under a minute · let go'
          : running
          ? 'Catching · since ${_since ??= _hm()}'
          : 'Falling away, uncaught',
      hint: running ? 'Tap the cell to let go' : 'Tap the cell to catch',
      cellAria: running ? 'End session' : 'Start session',
      hours: hours,
      tens: tens,
      mins: mins,
      fx: a == null ? const [] : _fuseBoxes(a),
    );
  }

  /// Variant 'fuse' of the artifact's `_fx`.
  List<BlockBox> _fuseBoxes(_Fuse a) {
    final p = a.p, s = a.srcSize, d = a.dstSize;
    final rs = s * 0.22, rD = d * 0.23;
    final out = <BlockBox>[];
    final dcx = a.dst.dx + d / 2, dcy = a.dst.dy + d / 2;
    final e1 = smooth(p / 0.55), fade = 1 - smooth((p - 0.5) / 0.3);
    for (final c in a.src) {
      out.add(
        BlockBox(
          rect: Rect.fromLTWH(
            c.dx + (dcx - s / 2 - c.dx) * e1,
            c.dy + (dcy - s / 2 - c.dy) * e1,
            s,
            s,
          ),
          radius: rs,
          opacity: _clamp01(fade),
        ),
      );
    }
    final e2 = smooth((p - 0.4) / 0.6);
    final sz = s + (d - s) * e2;
    out.add(
      BlockBox(
        rect: Rect.fromLTWH(dcx - sz / 2, dcy - sz / 2, sz, sz),
        radius: rs + (rD - rs) * e2,
        opacity: _clamp01(smooth((p - 0.4) / 0.15)),
        solidLight: p < 0.82,
        glowBlur: (8 + 18 * math.sin(math.pi * e2)).roundToDouble(),
        glowSpread: 2,
        glowAlpha: 0.7,
      ),
    );
    return out;
  }
}
