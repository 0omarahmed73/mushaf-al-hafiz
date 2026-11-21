// Night Reader's page is the same page (spec FR-008, SC-004; research D3): for the sampled pages (every page with
// `--dart-define=FULL_LAYOUT_CHECK=true`) the real fonts lay out the same words on the same lines in the same order, in
// the same boxes, in Emerald & Gold and in Night. It does not edit feature 003's invariance test.
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mushaf/mushaf/models.dart';
import 'package:mushaf/mushaf/mushaf_page.dart' show MushafPage, kTitleFont;
import 'package:mushaf/mushaf/mushaf_page_card.dart';
import 'package:mushaf/mushaf/mushaf_repository.dart';
import 'package:mushaf/mushaf/page_font_loader.dart';
import 'package:mushaf/mushaf/page_look.dart';
import 'package:mushaf/theme.dart';

const Size kBox = Size(412, 763);

Future<void> _loadFont(String family, String asset) async {
  final loader = FontLoader(family)..addFont(rootBundle.load(asset));
  await loader.load();
}

bool _isWord(Widget w) {
  final key = w.key;
  return key is ValueKey<String> && RegExp(r'^w\d+$').hasMatch(key.value);
}

const bool kFull = bool.fromEnvironment('FULL_LAYOUT_CHECK');

/// The first and last pages, the surah starts around them, page 50, al-Kahf's first page 293, and every sixth page;
/// all 604 with the flag.
bool _covered(int page) =>
    kFull ||
    page <= 4 ||
    page >= 600 ||
    page == 50 ||
    page == 293 ||
    page % 6 == 1;

/// What a page lays out: the box of the page, then for each line its box and the ids and boxes of its words.
List<Object> snapshot(WidgetTester t, PageData data) {
  final out = <Object>[t.getRect(find.byType(MushafPage))];
  for (final line in data.lines) {
    final lineFinder = find.byKey(ValueKey('line-${line.number}'));
    out.add(t.getRect(lineFinder));
    final words = find.descendant(
      of: lineFinder,
      matching: find.byWidgetPredicate(_isWord),
    );
    for (final e in words.evaluate()) {
      final box = e.renderObject! as RenderBox;
      out
        ..add((e.widget.key! as ValueKey<String>).value)
        ..add(box.localToGlobal(Offset.zero) & box.size);
    }
  }
  return out;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final mushaf = MushafRepository(rootBundle);
  final fonts = PageFontLoader();
  late MushafMeta meta;

  setUpAll(() async {
    meta = await mushaf.loadMeta();
  });

  final shown = ValueNotifier<(PageData, String, PageLook)?>(null);

  Future<void> start(WidgetTester t) => t.pumpWidget(
    MaterialApp(
      theme: buildAppTheme(),
      home: Scaffold(
        body: ValueListenableBuilder<(PageData, String, PageLook)?>(
          valueListenable: shown,
          builder: (context, value, _) {
            if (value == null) return const SizedBox();
            final (data, family, look) = value;
            return Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: kBox.width,
                height: kBox.height,
                child: MushafPageCard(
                  data: data,
                  meta: meta,
                  fontFamily: family,
                  look: look,
                ),
              ),
            );
          },
        ),
      ),
    ),
  );

  for (var from = 1; from <= 604; from += 100) {
    final to = from + 99 > 604 ? 604 : from + 99;
    testWidgets('pages $from..$to are laid out the same in both looks', (
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
        shown.value = (data, family, PageLook.screen);
        await t.pump();
        expect(t.takeException(), isNull, reason: 'page $p in Emerald');
        final emerald = snapshot(t, data);
        shown.value = (data, family, PageLook.night);
        await t.pump();
        expect(t.takeException(), isNull, reason: 'page $p in Night');
        final night = snapshot(t, data);
        expect(night, emerald, reason: 'page $p: same lines, words and boxes');
      }
    }, timeout: const Timeout(Duration(minutes: 5)));
  }
}
