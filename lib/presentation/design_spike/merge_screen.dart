import 'package:flutter/material.dart' show Material, MaterialType;
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import 'merge_controller.dart';
import 'merge_scene_painter.dart';
import 'nav_button.dart';
import 'spike_tokens.dart';

/// "Merge 1 · Gather and fuse": one interactive 390x844 phone screen.
/// The fixed-size design is scaled to fit whatever the device gives us.
class MergeScreen extends StatefulWidget {
  const MergeScreen({super.key, this.controller, this.autoTick = true});

  final MergeController? controller;

  /// False in tests: the test steps the controller itself.
  final bool autoTick;

  @override
  State<MergeScreen> createState() => _MergeScreenState();
}

class _MergeScreenState extends State<MergeScreen>
    with TickerProviderStateMixin {
  late final MergeController _c = widget.controller ?? MergeController();
  late final AnimationController _press = AnimationController(
    vsync: this,
    duration: SpikeMotion.press,
  );
  late final CurvedAnimation _pressCurve = CurvedAnimation(
    parent: _press,
    curve: SpikeMotion.cssEase,
  );
  Ticker? _ticker;
  Duration _last = Duration.zero;

  @override
  void initState() {
    super.initState();
    if (widget.autoTick) {
      _ticker = createTicker((elapsed) {
        final dt = (elapsed - _last).inMicroseconds / 1e6;
        _last = elapsed;
        _c.advance(dt);
      })..start();
    }
  }

  @override
  void dispose() {
    _ticker?.dispose();
    _pressCurve.dispose();
    _press.dispose();
    if (widget.controller == null) _c.dispose();
    super.dispose();
  }

  double get _scale =>
      1 - (1 - SpikeMetrics.cellPressScale) * _pressCurve.value;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: SpikeColors.screenBase,
      child: Center(
        child: FittedBox(
          child: SizedBox(
            width: SpikeMetrics.width,
            height: SpikeMetrics.height,
            child: Material(
              type: MaterialType.transparency,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: RepaintBoundary(
                      child: CustomPaint(
                        painter: MergeScenePainter(
                          frame: () => _c.frame,
                          pressScale: () => _scale,
                          repaint: Listenable.merge([_c, _press]),
                        ),
                      ),
                    ),
                  ),
                  _cellTarget(),
                  Positioned(
                    left: SpikeMetrics.navInset,
                    bottom: SpikeMetrics.navBottom,
                    child: const NavButton(
                      label: 'History',
                      icon: NavIcon.history,
                    ),
                  ),
                  Positioned(
                    right: SpikeMetrics.navInset,
                    bottom: SpikeMetrics.navBottom,
                    child: const NavButton(
                      label: 'Count dhikr',
                      icon: NavIcon.dhikr,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Transparent tap target that follows the painted cell.
  Widget _cellTarget() {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) => Positioned(
        left: _c.frame.cellX,
        top: SpikeMetrics.cellTop,
        width: SpikeMetrics.cellSize,
        height: SpikeMetrics.cellSize,
        child: Semantics(
          button: true,
          label: _c.frame.cellAria,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (_) => _press.forward(),
            onTapUp: (_) => _press.reverse(),
            onTapCancel: () => _press.reverse(),
            onTap: _c.toggle,
          ),
        ),
      ),
    );
  }
}
