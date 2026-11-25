// SC-001 and constitution 2.2.0 Principle I: over the whole Mushaf, the large-ayah screens hold every word of every ayah
// exactly once and in order, never two pages, split ayat in numbered consecutive parts, and lose no surah opening.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mushaf/ayah/ayah_ref.dart';
import 'package:mushaf/large_ayah/screen_layout.dart';
import 'package:mushaf/mushaf/models.dart';

List<PageData> _pages() => [
  for (var p = 1; p <= 604; p++)
    PageData.fromJson(
      jsonDecode(File('assets/mushaf/pages/p${p.toString().padLeft(3, '0')}.json').readAsStringSync())
          as Map<String, dynamic>,
    ),
];

/// Checks the screens of [page] against the page itself; returns the ayat in screen order.
List<AyahRef> _check(PageData page, List<LargeScreen> screens, String label) {
  final expectedWords = [
    for (final l in page.lines)
      if (l.type == LineType.ayah) ...l.words.map((w) => w.id),
  ];
  final got = [for (final s in screens) ...s.words.map((w) => w.id)];
  expect(got, expectedWords, reason: '$label page ${page.page}: every word once, in order');
  final titles = page.lines.where((l) => l.type == LineType.surahName).map((l) => l.surah).toList();
  final gotTitles = [
    for (final s in screens)
      for (final o in s.opening)
        if (o.kind == OpeningKind.surahTitle) o.surah,
  ];
  expect(gotTitles, titles, reason: '$label page ${page.page}: every surah title kept');
  final basmalas = page.lines.where((l) => l.type == LineType.basmallah).length;
  expect(
    screens.expand((s) => s.opening).where((o) => o.kind == OpeningKind.basmala).length,
    basmalas,
    reason: '$label page ${page.page}: every basmala kept',
  );
  final order = <AyahRef>[];
  for (var i = 0; i < screens.length; i++) {
    final s = screens[i];
    expect(s.page, page.page);
    expect(s.ayat, isNotEmpty);
    final part = s.part;
    if (part != null) {
      expect(s.ayat, hasLength(1));
      if (part.number > 1) {
        expect(screens[i - 1].part, (number: part.number - 1, of: part.of), reason: '$label page ${page.page}');
        expect(screens[i - 1].ayat, s.ayat);
        continue;
      }
    }
    order.addAll(s.ayat);
  }
  return order;
}

void _wholeMushaf(List<PageData> pages, double Function(MushafWord w) width, String label) {
  for (final count in [1, 2, 3]) {
    for (final lines in [6, 12]) {
      final all = <AyahRef>[];
      for (final page in pages) {
        final ayat = [
          for (final a in pageAyat(page)) a.withWidths([for (final w in a.words) width(w)]),
        ];
        final screens = layoutPage(
          page: page.page,
          ayat: ayat,
          lineWidth: 6,
          wordGap: 0.3,
          linesPerScreen: lines,
          count: count,
        );
        for (final s in screens) {
          expect(s.ayat.length, lessThanOrEqualTo(count));
        }
        all.addAll(_check(page, screens, '$label count $count lines $lines'));
      }
      expect(all, hasLength(6236), reason: '$label count $count lines $lines: 6,236 ayat');
      expect(all.toSet(), hasLength(6236), reason: 'each ayah once');
      for (var i = 1; i < all.length; i++) {
        final a = all[i - 1], b = all[i];
        expect(b.surah > a.surah || (b.surah == a.surah && b.ayah == a.ayah + 1), isTrue, reason: '$a then $b');
      }
    }
  }
}

void main() {
  final pages = _pages();

  test('stand-in widths of 1 unit a word', () {
    _wholeMushaf(pages, (_) => 1, 'unit');
  });

  test('stand-in widths from the glyph length', () {
    _wholeMushaf(pages, (w) => 0.5 * w.glyph.length, 'glyph-length');
  });

  testWidgets('real glyph widths for chosen pages at size steps 1 and 3', (t) async {
    const chosen = [1, 2, 48, 50, 187, 300, 582, 604];
    await t.runAsync(() async {
      for (final p in chosen) {
        final loader = FontLoader('qpc_p$p')..addFont(rootBundle.load('assets/fonts/qpc-v2/p$p.ttf'));
        await loader.load();
      }
    });
    for (final factor in [2.0, 3.0]) {
      const width = 328.0; // 360 dp less 2 x 16
      final fontSize = factor * width / 16.2;
      for (final p in chosen) {
        final page = pages[p - 1];
        final ayat = [
          for (final a in pageAyat(page))
            a.withWidths([
              for (final w in a.words)
                (TextPainter(
                  text: TextSpan(
                    text: w.glyph,
                    style: TextStyle(fontFamily: 'qpc_p$p', fontSize: fontSize),
                  ),
                  textDirection: TextDirection.rtl,
                )..layout()).width,
            ]),
        ];
        final screens = layoutPage(
          page: p,
          ayat: ayat,
          lineWidth: width,
          wordGap: fontSize * 0.25,
          linesPerScreen: 7,
          count: 3,
        );
        _check(page, screens, 'real x$factor');
        for (final s in screens) {
          for (final line in s.lines) {
            if (line.length < 2) continue;
            final i = page.lines.expand((l) => l.words).toList();
            final used =
                [for (final w in line) ayat.expand((a) => a.widths).elementAt(i.indexOf(w))]
                    .fold<double>(0, (a, b) => a + b) +
                fontSize * 0.25 * (line.length - 1);
            expect(used, lessThanOrEqualTo(width + 0.01), reason: 'page $p line fits');
          }
        }
      }
    }
  });
}
