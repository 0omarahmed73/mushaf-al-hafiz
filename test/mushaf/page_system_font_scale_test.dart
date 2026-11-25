// The phone's own font size must not change the Mushaf page (Constitution II, the A52 report of 2026-11-25): with
// the system text scale at 1.3 or 2.0 the real fonts lay out the same words in the same rectangles as at 1.0, and
// no line is wider than its box. The page's size is the app's own setting (feature 003), never the system's.
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mushaf/mushaf/models.dart';
import 'package:mushaf/mushaf/mushaf_page.dart'
    show kTitleFont, MushafPageLoading;
import 'package:mushaf/mushaf/mushaf_page_card.dart';
import 'package:mushaf/mushaf/mushaf_repository.dart';
import 'package:mushaf/mushaf/page_font_loader.dart';
import 'package:mushaf/theme.dart';

/// The portrait box of a phone like the A52 or the owner's, in logical pixels.
const Size kBox = Size(412, 763);

const List<int> kPages = [1, 2, 3, 50, 187, 300, 442, 582, 600, 604];

Future<void> _loadFont(String family, String asset) async {
  final loader = FontLoader(family)..addFont(rootBundle.load(asset));
  await loader.load();
}

bool _isWord(Widget w) {
  final key = w.key;
  return key is ValueKey<String> && RegExp(r'^w\d+$').hasMatch(key.value);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final mushaf = MushafRepository(rootBundle);
  final fonts = PageFontLoader();
  late MushafMeta meta;

  setUpAll(() async {
    meta = await mushaf.loadMeta();
  });

  final shown = ValueNotifier<(Widget, double)?>(null);

  Future<void> start(WidgetTester t) => t.pumpWidget(
    MaterialApp(
      theme: buildAppTheme(),
      home: Scaffold(
        body: ValueListenableBuilder<(Widget, double)?>(
          valueListenable: shown,
          builder: (context, value, _) {
            if (value == null) return const SizedBox();
            final (child, scale) = value;
            return MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: TextScaler.linear(scale)),
              child: Align(
                alignment: Alignment.topLeft,
                child: SizedBox(
                  width: kBox.width,
                  height: kBox.height,
                  child: child,
                ),
              ),
            );
          },
        ),
      ),
    ),
  );

  Map<String, Rect> words(WidgetTester t) => {
    for (final e in find.byWidgetPredicate(_isWord).evaluate())
      (e.widget.key! as ValueKey<String>).value: () {
        final box = e.renderObject! as RenderBox;
        return box.localToGlobal(Offset.zero) & box.size;
      }(),
  };

  testWidgets(
    'the system font size does not move or grow any word of the page',
    (t) async {
      t.view.physicalSize = const Size(1000, 1400);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      await start(t);
      final loaded = <int, (PageData, String)>{};
      await t.runAsync(() async {
        await _loadFont(kTitleFont, 'assets/fonts/reemkufi/ReemKufi.ttf');
        await _loadFont('AmiriQuran', 'assets/fonts/amiri/AmiriQuran.ttf');
        await _loadFont(kUiFont, 'assets/fonts/cairo/Cairo-Regular.ttf');
        for (final p in kPages) {
          loaded[p] = (await mushaf.loadPage(p), await fonts.ensure(p));
        }
      });
      for (final p in kPages) {
        final (data, family) = loaded[p]!;
        final card = MushafPageCard(data: data, meta: meta, fontFamily: family);
        shown.value = (card, 1.0);
        await t.pump();
        expect(t.takeException(), isNull, reason: 'page $p at 1.0');
        final base = words(t);
        expect(base, isNotEmpty);
        for (final scale in [1.3, 2.0]) {
          shown.value = (card, scale);
          await t.pump();
          final problem = t.takeException();
          expect(
            problem,
            isNull,
            reason: 'page $p at system scale $scale: $problem',
          );
          final now = words(t);
          expect(
            now.keys.toList(),
            base.keys.toList(),
            reason: 'page $p at $scale: same words',
          );
          for (final id in base.keys) {
            final a = base[id]!, b = now[id]!;
            expect(
              (a.left - b.left).abs() < 0.01 &&
                  (a.top - b.top).abs() < 0.01 &&
                  (a.width - b.width).abs() < 0.01 &&
                  (a.height - b.height).abs() < 0.01,
              isTrue,
              reason: 'page $p word $id at system scale $scale: $a became $b',
            );
          }
        }
      }
    },
    timeout: const Timeout(Duration(minutes: 3)),
  );

  testWidgets(
    'the loading page keeps its page number size with a large system font',
    (t) async {
      await start(t);
      shown.value = (const MushafPageLoading(page: 12), 1.0);
      await t.pump();
      final base = t.getSize(find.byKey(const ValueKey('page-number')));
      shown.value = (const MushafPageLoading(page: 12), 2.0);
      await t.pump();
      expect(t.takeException(), isNull);
      expect(t.getSize(find.byKey(const ValueKey('page-number'))), base);
    },
  );
}
