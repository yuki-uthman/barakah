import 'package:flutter/foundation.dart';

import 'merge_frame.dart';
import 'merge_model.dart';

/// Owns the [MergeModel] and the frame the painter draws. Driven by the
/// screen's ticker in the app, or stepped by hand in tests.
class MergeController extends ChangeNotifier {
  MergeController({MergeModel? model}) : model = model ?? MergeModel() {
    frame = this.model.frame();
  }

  final MergeModel model;
  late MergeFrame frame;
  double _time = 0;

  double get time => _time;

  void advance(double dt) {
    _time += dt;
    model.tick(dt, _time);
    frame = model.frame();
    notifyListeners();
  }

  void toggle() {
    model.toggle();
    frame = model.frame();
    notifyListeners();
  }
}
