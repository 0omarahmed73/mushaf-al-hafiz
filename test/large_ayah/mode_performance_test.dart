// Guards, not promises to the owner (feature 015, plan Performance Goals): a page's screens are laid out quickly, a swipe
// builds the incoming screen at most once, and the view shows its first screen soon after the page font is ready.
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mushaf/large_ayah/large_ayah_screen.dart';
import 'package:mushaf/large_ayah/page_screens.dart';
import 'package:mushaf/large_ayah/word_measurer.dart';
import 'package:mushaf/mushaf/mushaf_repository.dart';
import 'package:mushaf/mushaf/page_font_loader.dart';

import '../support/large_ayah_harness.dart';
import '../support/reader_harness.dart';

void main() {
  testWidgets('laying out a page\'s screens takes under 30 ms once its data and font are there', (t) async {
    final mushaf = MushafRepository(rootBundle);
    final fonts = PageFontLoader();
    final g = LargeGeometry(width: 412, height: 800, factor: 2.0);
    for (final p in [1, 48, 300, 604]) {
      await t.runAsync(() async {
        await mushaf.loadPage(p);
        await fonts.ensure(p);
      });
      final source = PageScreens(mushaf: mushaf, measurer: WordMeasurer(fonts), geometry: g, count: 3);
      final watch = Stopwatch()..start();
      await t.runAsync(() => source.screensOf(p));
      watch.stop();
      expect(watch.elapsedMilliseconds, lessThan(30), reason: 'page $p took ${watch.elapsedMilliseconds} ms');
    }
  });

  testWidgets('a swipe builds the incoming screen at most once', (t) async {
    await pumpLargeReader(t, startPage: 3, on: true);
    final builds = <int>[];
    final before = shownLargeScreen(t).screen.ayat.first;
    // Count the LargeAyahScreen elements made during one swipe.
    final seen = <Element>{};
    void record() {
      for (final e in find.byType(LargeAyahScreen, skipOffstage: false).evaluate()) {
        if (seen.add(e)) builds.add(1);
      }
    }

    record();
    final start = builds.length;
    final gesture = await t.startGesture(const Offset(100, 400));
    for (var i = 0; i < 10; i++) {
      await gesture.moveBy(const Offset(30, 0));
      await t.pump(const Duration(milliseconds: 16));
      record();
    }
    await gesture.up();
    await settleReader(t);
    record();
    expect(shownLargeScreen(t).screen.ayat.first, isNot(before));
    expect(
      builds.length - start,
      lessThanOrEqualTo(2),
      reason: 'the next screen, and at most the one after it, are made',
    );
  });

  testWidgets('turning the view on shows the first screen within 300 ms once the font is loaded', (t) async {
    final r = await pumpLargeReader(t, startPage: 3);
    final watch = Stopwatch()..start();
    await t.runAsync(() => r.settings.setOn(true));
    var shown = false;
    for (var i = 0; i < 30 && !shown; i++) {
      await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 10)));
      await t.pump(const Duration(milliseconds: 10));
      shown = find.byType(LargeAyahScreen).evaluate().isNotEmpty;
    }
    watch.stop();
    expect(shown, isTrue);
    expect(watch.elapsedMilliseconds, lessThan(300));
  });
}
