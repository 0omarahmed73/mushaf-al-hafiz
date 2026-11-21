// A bigger or smaller page is the same page: for every one of the 604 pages at every size of the setting, the
// real fonts lay out the same words on the same lines, in the same order, with no line wider than its box
// (spec FR-009, SC-003; research D2). It checks the current page code, so it passes before the viewport exists.
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mushaf/mushaf/models.dart';
import 'package:mushaf/mushaf/mushaf_page_card.dart';
import 'package:mushaf/mushaf/mushaf_repository.dart';
import 'package:mushaf/mushaf/page_font_loader.dart';
import 'package:mushaf/mushaf/mushaf_page.dart' show kTitleFont;
import 'package:mushaf/settings/text_size.dart';
import 'package:mushaf/theme.dart';

/// The portrait box of a phone like the owner's, in logical pixels, at 100%.
const Size kBase = Size(412, 763);

Future<void> _loadFont(String family, String asset) async {
  final loader = FontLoader(family)..addFont(rootBundle.load(asset));
  await loader.load();
}

bool _isWord(Widget w) {
  final key = w.key;
  return key is ValueKey<String> && RegExp(r'^w\d+$').hasMatch(key.value);
}

/// Every page at every size takes about four minutes. The default run checks the first and last pages (the
/// short ones, the surah starts) and every sixth page; `--dart-define=FULL_LAYOUT_CHECK=true` checks all 604.
const bool kFull = bool.fromEnvironment('FULL_LAYOUT_CHECK');

bool _covered(int page) => kFull || page <= 4 || page >= 600 || page % 6 == 1;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final mushaf = MushafRepository(rootBundle);
  final fonts = PageFontLoader();
  late MushafMeta meta;

  setUpAll(() async {
    // rootBundle remembers Futures, so everything is loaded in real time before any test pumps.
    meta = await mushaf.loadMeta();
  });

  /// One app for the whole test; only the page under it changes, so the time goes into the page layout.
  final shown = ValueNotifier<(PageData, String, int)?>(null);

  Future<void> start(WidgetTester t) => t.pumpWidget(
    MaterialApp(
      theme: buildAppTheme(),
      home: Scaffold(
        body: ValueListenableBuilder<(PageData, String, int)?>(
          valueListenable: shown,
          builder: (context, value, _) {
            if (value == null) return const SizedBox();
            final (data, family, percent) = value;
            final box = Size(
              kBase.width * percent / 100,
              kBase.height * percent / 100,
            );
            return Align(
              alignment: Alignment.topLeft,
              child: OverflowBox(
                alignment: Alignment.topLeft,
                minWidth: box.width,
                maxWidth: box.width,
                minHeight: box.height,
                maxHeight: box.height,
                child: MushafPageCard(
                  data: data,
                  meta: meta,
                  fontFamily: family,
                ),
              ),
            );
          },
        ),
      ),
    ),
  );

  Future<void> check(
    WidgetTester t,
    int page,
    PageData data,
    String family,
    int percent,
  ) async {
    shown.value = (data, family, percent);
    await t.pump();
    final problem = t.takeException();
    expect(problem, isNull, reason: 'page $page at $percent%: $problem');
    for (final line in data.lines) {
      final lineFinder = find.byKey(ValueKey('line-${line.number}'));
      expect(
        lineFinder,
        findsOneWidget,
        reason: 'page $page line ${line.number} at $percent%',
      );
      final words = find.descendant(
        of: lineFinder,
        matching: find.byWidgetPredicate(_isWord),
      );
      final ids = [
        for (final e in words.evaluate())
          (e.widget.key! as ValueKey<String>).value,
      ];
      expect(
        ids,
        [for (final w in line.words) 'w${w.id}'],
        reason:
            'page $page line ${line.number} at $percent%: same words in the same order',
      );
      if (line.type != LineType.ayah) continue;
      final lineBox = lineFinder.evaluate().single.renderObject! as RenderBox;
      final lineRect = lineBox.localToGlobal(Offset.zero) & lineBox.size;
      for (final e in words.evaluate()) {
        final box = e.renderObject! as RenderBox;
        final r = box.localToGlobal(Offset.zero) & box.size;
        expect(
          r.left,
          greaterThanOrEqualTo(lineRect.left - 0.5),
          reason: 'page $page line ${line.number} at $percent%',
        );
        expect(
          r.right,
          lessThanOrEqualTo(lineRect.right + 0.5),
          reason: 'page $page line ${line.number} at $percent%',
        );
      }
    }
  }

  // 604 pages in groups, each group one test, so a failure names its pages.
  for (var from = 1; from <= 604; from += 100) {
    final to = from + 99 > 604 ? 604 : from + 99;
    testWidgets('pages $from..$to keep their lines and words at every size', (
      t,
    ) async {
      t.view.physicalSize = const Size(1000, 1400);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      await start(t);
      final loaded = <int, (PageData, String)>{};
      await t.runAsync(() async {
        await _loadFont(kTitleFont, 'assets/fonts/reemkufi/ReemKufi.ttf');
        await _loadFont('AmiriQuran', 'assets/fonts/amiri/AmiriQuran.ttf');
        await _loadFont(kUiFont, 'assets/fonts/cairo/Cairo-Regular.ttf');
        for (var p = from; p <= to; p++) {
          if (_covered(p)) {
            loaded[p] = (await mushaf.loadPage(p), await fonts.ensure(p));
          }
        }
      });
      for (var p = from; p <= to; p++) {
        if (!_covered(p)) continue;
        final (data, family) = loaded[p]!;
        for (final percent in TextSize.steps) {
          await check(t, p, data, family, percent);
        }
      }
    }, timeout: const Timeout(Duration(minutes: 5)));
  }
}
