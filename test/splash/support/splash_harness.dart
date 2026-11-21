import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mushaf/splash/app_icon_painter.dart';
import 'package:mushaf/splash/splash_painters.dart';

/// Fake-time helpers for the splash tests. A ticker's first frame only sets its start time, so [startSplash] pumps twice: after
/// it the splash's clock reads 0 ms and every `tester.pump(Duration)` advances it by exactly that much.
Future<void> startSplash(WidgetTester tester, Widget widget) async {
  await tester.pumpWidget(widget);
  await tester.pump();
}

Future<void> after(WidgetTester tester, int milliseconds) =>
    tester.pump(Duration(milliseconds: milliseconds));

/// Advances the clock by [milliseconds] in frames of [step] ms, like a phone does (the splash decides what to do on a frame,
/// so one big pump would move its decisions to the end of the pump).
Future<void> advance(
  WidgetTester tester,
  int milliseconds, {
  int step = 10,
}) async {
  var left = milliseconds;
  while (left > 0) {
    final d = left < step ? left : step;
    await tester.pump(Duration(milliseconds: d));
    left -= d;
  }
}

/// The share of the light that gets through all the `Opacity` widgets above [finder] (1 = fully shown, 0 = invisible).
double shownAmount(WidgetTester tester, Finder finder) {
  var amount = 1.0;
  for (final o in tester.widgetList<Opacity>(
    find.ancestor(of: finder, matching: find.byType(Opacity)),
  )) {
    amount *= o.opacity;
  }
  return amount;
}

Finder get iconTile => find.byWidgetPredicate(
  (w) => w is CustomPaint && w.painter is AppIconPainter,
);

Finder get thinLine => find.byWidgetPredicate(
  (w) => w is CustomPaint && w.painter is ProgressLinePainter,
);

AppIconPainter iconPainter(WidgetTester tester) =>
    tester.widget<CustomPaint>(iconTile).painter! as AppIconPainter;

double lineProgress(WidgetTester tester) =>
    (tester.widget<CustomPaint>(thinLine).painter! as ProgressLinePainter)
        .progress;

/// Makes the test window [width] x [height] logical pixels at a device ratio of 1 (and puts it back at the end).
void setWindow(WidgetTester tester, double width, double height) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = Size(width, height);
  addTearDown(tester.view.reset);
}
