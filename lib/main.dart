import 'package:flutter/widgets.dart';

import 'presentation/design_spike/merge_screen.dart';

/// Design spike: the home screen is the recreated "Merge 1" artifact.
void main() {
  runApp(
    WidgetsApp(
      color: Color(0xFF0C1710),
      debugShowCheckedModeBanner: false,
      home: const MergeScreen(),
      pageRouteBuilder: _route,
    ),
  );
}

PageRoute<T> _route<T>(RouteSettings s, WidgetBuilder b) =>
    PageRouteBuilder<T>(settings: s, pageBuilder: (c, _, __) => b(c));
