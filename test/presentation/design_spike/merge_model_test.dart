import 'package:barakah/presentation/design_spike/merge_model.dart';
import 'package:flutter_test/flutter_test.dart';

import 'spike_test_utils.dart';

void main() {
  test('starts running with a fifth of a minute and 47 cells', () {
    final c = makeController();
    final m = c.model;
    expect(m.running, isTrue);
    expect(m.cells, 47);
    expect(m.frac, closeTo(0.2, 1e-9));
    expect(c.frame.status, startsWith('Catching'));
    expect(c.frame.totalText, '00:47:12');
    expect(c.frame.clockText, '09:30:00');
  });

  test('fills the cell at demoSpeed/60 per second', () {
    final c = makeController(demoSpeed: 6);
    step(c, 3);
    expect(c.model.frac, closeTo(0.2 + 3 * 6 / 60, 0.02));
  });

  test('a full minute sends the cell flying for 0.8 s, then lands a unit', () {
    final c = makeController(demoSpeed: 60);
    c.model.debugSetFrac(0.99);
    expect(stepUntil(c, () => c.model.flying), isTrue);
    expect(c.frame.flyer, isNotNull);
    expect(c.model.cells, 47);
    step(c, 0.75);
    expect(c.model.flying, isTrue);
    step(c, 0.1);
    expect(c.model.flying, isFalse);
    expect(c.model.cells, 48);
    expect(c.frame.flyer, isNull);
  });

  test('ten units fuse into a ten-block over 0.8 s', () {
    final c = makeController(demoSpeed: 60);
    c.model.cells = 59;
    c.model.debugSetFrac(0.99);
    expect(stepUntil(c, () => c.model.fusingTen), isTrue);
    expect(c.frame.fx, isNotEmpty);
    expect(c.frame.fx.length, 11); // 10 sources + merged piece
    expect(stepUntil(c, () => !c.model.fusing), isTrue);
    expect(c.model.dT, 6); // ten landed; six tens now roll into an hour
    expect(stepUntil(c, () => c.model.dH == 1 && !c.model.fusing), isTrue);
    expect(c.model.dT, 0);
  });

  test('six tens fuse into an hour-block', () {
    final c = makeController(demoSpeed: 60);
    c.model.cells = 119;
    c.model.debugSetFrac(0.99);
    expect(stepUntil(c, () => c.model.fusing && !c.model.fusingTen), isTrue);
    expect(c.frame.fx.length, 7); // 6 tens + merged piece
    expect(stepUntil(c, () => !c.model.fusing), isTrue);
    expect(c.model.dH, 2);
    expect(c.frame.hours.length, 2);
  });

  test('letting go under a minute restores the cell count and fraction', () {
    final c = makeController(demoSpeed: 1);
    step(c, 2);
    c.toggle();
    expect(c.model.undo, isTrue);
    expect(c.frame.status, 'Under a minute · let go');
    step(c, 4);
    expect(c.model.undo, isFalse);
    expect(c.model.frac, closeTo(0.2, 1e-9));
    expect(c.frame.status, 'Falling away, uncaught');
    expect(c.frame.hint, 'Tap the cell to catch');
  });

  test('cell slides between idle and run x with smoothstep', () {
    final c = makeController(running: false);
    step(c, 3);
    expect(c.frame.cellX, closeTo(231, 0.5));
    c.toggle();
    step(c, 3);
    expect(c.frame.cellX, closeTo(135, 0.5));
  });

  test('smoothstep clamps and is symmetric', () {
    expect(smooth(-1), 0);
    expect(smooth(2), 1);
    expect(smooth(0.5), 0.5);
  });

  test('stream ends on the cell surface when it covers the stream', () {
    final c = makeController();
    step(c, 2);
    // surface = 330 + 120 * (1 - frac) ~ 426 -> metrics end there, not 452
    final end = c.frame.stream.getBounds().bottom;
    expect(end, lessThan(451));
  });
}
