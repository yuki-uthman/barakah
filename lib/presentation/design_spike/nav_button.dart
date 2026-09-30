import 'package:flutter/widgets.dart';

import 'spike_tokens.dart';

enum NavIcon { history, dhikr }

/// 60px round outlined button with a 26px stroke icon (24 viewBox, 1.6 stroke).
class NavButton extends StatelessWidget {
  const NavButton({super.key, required this.label, required this.icon});

  final String label;
  final NavIcon icon;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: Container(
        width: SpikeMetrics.navButton,
        height: SpikeMetrics.navButton,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: SpikeColors.navFill,
          border: Border.all(color: SpikeColors.navBorder),
        ),
        alignment: Alignment.center,
        child: CustomPaint(
          size: const Size.square(SpikeMetrics.navIcon),
          painter: _NavIconPainter(icon),
        ),
      ),
    );
  }
}

class _NavIconPainter extends CustomPainter {
  _NavIconPainter(this.icon);
  final NavIcon icon;

  @override
  void paint(Canvas canvas, Size size) {
    final k = size.width / 24;
    canvas.scale(k);
    final p = Path();
    switch (icon) {
      case NavIcon.history:
        p
          ..moveTo(5, 19)
          ..relativeLineTo(0, -7)
          ..moveTo(12, 19)
          ..lineTo(12, 5)
          ..moveTo(19, 19)
          ..relativeLineTo(0, -5);
      case NavIcon.dhikr:
        p
          ..moveTo(12, 3.5)
          ..relativeLineTo(0, 9)
          ..moveTo(8.5, 6.5)
          ..relativeLineTo(0, 6)
          ..moveTo(15.5, 6.5)
          ..relativeLineTo(0, 6)
          ..moveTo(5.5, 10.5)
          ..relativeLineTo(0, 3)
          ..arcToPoint(
            const Offset(18.5, 13.5),
            radius: const Radius.circular(6.5),
            clockwise: false,
          )
          ..relativeLineTo(0, -3);
    }
    canvas.drawPath(
      p,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = SpikeMetrics.navIconStroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = SpikeColors.gold,
    );
  }

  @override
  bool shouldRepaint(_NavIconPainter old) => old.icon != icon;
}
