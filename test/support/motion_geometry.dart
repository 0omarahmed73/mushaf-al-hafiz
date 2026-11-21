// The line and word rectangles of the page on the screen, for the tests that prove a motion never moves the Mushaf page
// (feature 010 SC-004). Only widgets that are on stage are read.
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

final RegExp _wordKey = RegExp(r'^w\d+$');

/// The rectangle of the pager, of every line (`line-N`) and of every word (`w<id>`) of the page shown.
Map<String, Rect> pageRects(WidgetTester t) {
  final rects = <String, Rect>{'pager': t.getRect(find.byType(PageView))};
  for (final element in find.byWidgetPredicate((w) {
    final key = w.key;
    return key is ValueKey<String> &&
        (key.value.startsWith('line-') || _wordKey.hasMatch(key.value));
  }).evaluate()) {
    final key = (element.widget.key! as ValueKey<String>).value;
    rects[key] = t.getRect(
      find.byElementPredicate((e) => identical(e, element)),
    );
  }
  return rects;
}

/// Pumps [frames] frames of 16 ms and expects every rectangle of [expected] to be where it was, in every frame.
Future<void> expectRectsStable(
  WidgetTester t,
  Map<String, Rect> expected, {
  int frames = 25,
  String? reason,
}) async {
  for (var f = 0; f < frames; f++) {
    await t.pump(const Duration(milliseconds: 16));
    final now = pageRects(t);
    for (final entry in expected.entries) {
      expect(
        now[entry.key],
        entry.value,
        reason:
            '${entry.key} moved in frame $f${reason == null ? '' : ' ($reason)'}',
      );
    }
  }
}
