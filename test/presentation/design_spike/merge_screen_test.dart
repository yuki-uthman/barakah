import 'package:barakah/presentation/design_spike/merge_controller.dart';
import 'package:barakah/presentation/design_spike/merge_screen.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'spike_test_utils.dart';

Future<void> pumpScreen(WidgetTester t, MergeController c) async {
  await t.binding.setSurfaceSize(const Size(390, 844));
  t.view.devicePixelRatio = 1;
  addTearDown(() => t.binding.setSurfaceSize(null));
  await t.pumpWidget(
    Directionality(
      textDirection: TextDirection.ltr,
      child: MergeScreen(controller: c, autoTick: false),
    ),
  );
}

void main() {
  setUpAll(loadSpikeFonts);

  testWidgets('state: catching (session running, cell under the stream)', (
    t,
  ) async {
    final c = makeController();
    step(c, 3);
    await pumpScreen(t, c);
    await expectLater(
      find.byType(MergeScreen),
      matchesGoldenFile('goldens/catching.png'),
    );
  });

  testWidgets('state: falling away (session stopped)', (t) async {
    final c = makeController(running: false);
    step(c, 3);
    await pumpScreen(t, c);
    await expectLater(
      find.byType(MergeScreen),
      matchesGoldenFile('goldens/stopped.png'),
    );
  });

  testWidgets('state: minute complete, cell flying to its slot', (t) async {
    final c = makeController(demoSpeed: 60);
    c.model.debugSetFrac(0.99);
    stepUntil(c, () => c.model.flying);
    step(c, 0.3);
    await pumpScreen(t, c);
    await expectLater(
      find.byType(MergeScreen),
      matchesGoldenFile('goldens/flying.png'),
    );
  });

  testWidgets('state: ten units fusing into a ten-block', (t) async {
    final c = makeController(demoSpeed: 60);
    c.model.cells = 59;
    c.model.debugSetFrac(0.99);
    stepUntil(c, () => c.model.fusingTen);
    step(c, 0.4);
    await pumpScreen(t, c);
    await expectLater(
      find.byType(MergeScreen),
      matchesGoldenFile('goldens/fuse_ten.png'),
    );
  });

  testWidgets('state: six tens fusing into an hour-block', (t) async {
    final c = makeController(demoSpeed: 60);
    c.model.cells = 119;
    c.model.debugSetFrac(0.99);
    stepUntil(c, () => c.model.fusing && !c.model.fusingTen);
    step(c, 0.4);
    await pumpScreen(t, c);
    await expectLater(
      find.byType(MergeScreen),
      matchesGoldenFile('goldens/fuse_hour.png'),
    );
  });

  testWidgets('tapping the cell toggles the session', (t) async {
    final c = makeController();
    step(c, 3);
    await pumpScreen(t, c);
    expect(find.bySemanticsLabel('End session'), findsOneWidget);
    await t.tap(find.bySemanticsLabel('End session'));
    await t.pump(const Duration(milliseconds: 200));
    expect(c.model.running, isFalse);
    expect(find.bySemanticsLabel('Start session'), findsOneWidget);
  });
}
