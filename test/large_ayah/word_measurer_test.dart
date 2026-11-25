// Glyph widths in the page fonts (feature 015, research D4).
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mushaf/large_ayah/word_measurer.dart';
import 'package:mushaf/mushaf/mushaf_repository.dart';
import 'package:mushaf/mushaf/page_font_loader.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('widths are positive and grow with the size; a page waits for its own font', (t) async {
    final fonts = PageFontLoader();
    final mushaf = MushafRepository(rootBundle);
    final measurer = WordMeasurer(fonts);
    for (final p in [1, 48, 604]) {
      final page = (await t.runAsync(() => mushaf.loadPage(p)))!;
      final words = [for (final l in page.lines) ...l.words];
      expect(fonts.isLoaded(p), isFalse);
      final small = (await t.runAsync(() => measurer.widths(p, words, 40)))!;
      expect(fonts.isLoaded(p), isTrue, reason: 'measuring loads the page font first');
      final big = (await t.runAsync(() => measurer.widths(p, words, 60)))!;
      expect(small, hasLength(words.length));
      for (var i = 0; i < words.length; i++) {
        expect(small[i], greaterThan(0));
        expect(big[i], closeTo(small[i] * 1.5, 1.0), reason: 'page $p word ${words[i].key}');
      }
    }
  });

  testWidgets('results are cached per page and size, for the last 8', (t) async {
    final measurer = WordMeasurer(PageFontLoader());
    final page = (await t.runAsync(() => MushafRepository(rootBundle).loadPage(2)))!;
    final words = [for (final l in page.lines) ...l.words];
    final a = (await t.runAsync(() => measurer.widths(2, words, 40)))!;
    final b = (await t.runAsync(() => measurer.widths(2, words, 40)))!;
    expect(identical(a, b), isTrue);
    expect(measurer.measured, 1);
    for (var size = 41.0; size < 49; size++) {
      await t.runAsync(() => measurer.widths(2, words, size));
    }
    final c = (await t.runAsync(() => measurer.widths(2, words, 40)))!;
    expect(identical(a, c), isFalse, reason: 'the oldest of 9 was dropped');
    expect(c, a);
  });
}
