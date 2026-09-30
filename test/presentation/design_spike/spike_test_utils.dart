import 'dart:io';

import 'package:barakah/presentation/design_spike/merge_controller.dart';
import 'package:barakah/presentation/design_spike/merge_model.dart';
import 'package:flutter/services.dart';

/// 14:30:00 → 9.5 h left of the day; keeps the flood level deterministic.
DateTime fixedNow() => DateTime(2026, 9, 30, 14, 30);

MergeController makeController({bool running = true, double demoSpeed = 1}) =>
    MergeController(
      model: MergeModel(
        sessionRunning: running,
        demoSpeed: demoSpeed,
        clock: fixedNow,
      ),
    );

void step(MergeController c, double seconds, {double dt = 1 / 30}) {
  var left = seconds;
  while (left > 1e-9) {
    final d = left < dt ? left : dt;
    c.advance(d);
    left -= d;
  }
}

/// Steps until [done] is true (max 30 s); returns false if it never was.
bool stepUntil(MergeController c, bool Function() done, {double dt = 1 / 30}) {
  for (var i = 0; i < 30 / dt; i++) {
    if (done()) return true;
    c.advance(dt);
  }
  return false;
}

Future<void> loadSpikeFonts() async {
  for (final e in {
    'CormorantGaramond': 'assets/fonts/CormorantGaramond-Variable.ttf',
    'EBGaramond': 'assets/fonts/EBGaramond-Variable.ttf',
  }.entries) {
    final bytes = File(e.value).readAsBytesSync();
    final loader = FontLoader(e.key)
      ..addFont(Future.value(ByteData.sublistView(bytes)));
    await loader.load();
  }
}
