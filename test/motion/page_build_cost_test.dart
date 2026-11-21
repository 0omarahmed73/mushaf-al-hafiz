// Feature 010 measurement M3: what it costs to build, rebuild and lay out one Mushaf page widget as the reader shows it
// (research.md H1 and H2). The test VM is JIT with asserts on, so absolute times are several times what a phone running
// the release build needs; the ratios and the element counts are what to read. Only generous bounds are asserted.
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mushaf/mushaf/models.dart';
import 'package:mushaf/mushaf/mushaf_page_card.dart';
import 'package:mushaf/mushaf/mushaf_repository.dart';
import 'package:mushaf/mushaf/page_font_loader.dart';
import 'package:mushaf/mushaf/page_look.dart';
import 'package:mushaf/mushaf/page_viewport.dart';

import '../support/motion_probe.dart';

/// The box the reader gives one page on a 412 x 915 phone: the screen less the two bars (84 + 68).
const Size _box = Size(412, 915 - 84 - 68);

Widget _host(ValueNotifier<int> tick, Size size, Widget Function() page) {
  return Directionality(
    textDirection: TextDirection.ltr,
    child: MediaQuery(
      data: MediaQueryData(size: size),
      child: ValueListenableBuilder<int>(
        valueListenable: tick,
        // A new card on every tick, as the reader's `_PageItem` makes one on every rebuild of the screen.
        builder: (context, _, _) =>
            SizedBox(width: size.width, height: size.height, child: page()),
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('M3: build, rebuild and relayout of a page (sample of pages)', (
    t,
  ) async {
    t.view.physicalSize = const Size(412, 915);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    final repo = MushafRepository(rootBundle);
    final fonts = PageFontLoader();
    final meta = (await t.runAsync(repo.loadMeta))!;

    final cold = <double>[];
    final fresh = <double>[];
    final warm = <double>[];
    final relayout = <double>[];
    final cachedTicks = <double>[];
    var cachedRebuilds = 0;
    var elementsTotal = 0;
    var textTotal = 0;
    var gestureTotal = 0;
    var paragraphTotal = 0;
    final pages = [1, 2, 50, 293, 450, 604];

    for (final p in pages) {
      late PageData data;
      late String family;
      await t.runAsync(() async {
        data = await repo.loadPage(p);
        family = await fonts.ensure(p);
      });
      final tick = ValueNotifier<int>(0);
      addTearDown(tick.dispose);
      var size = _box;
      Widget page() => PageViewport(
        page: p,
        factor: 1,
        onLockChanged: (_, _) {},
        onEdgeTurn: (_) {},
        child: MushafPageCard(
          data: data,
          meta: meta,
          fontFamily: family,
          look: PageLook.screen,
          onWordLongPress: (_) {},
          onPageNumberTap: () {},
        ),
      );

      // 1. First build with this font family: build + layout + paint recording of the whole page.
      final s0 = Stopwatch()..start();
      await t.pumpWidget(_host(tick, size, page));
      s0.stop();
      cold.add(ms(s0));

      final root = t.element(find.byType(MushafPageCard));
      elementsTotal += subtreeSize(root);
      textTotal += find
          .descendant(
            of: find.byType(MushafPageCard),
            matching: find.byType(Text),
          )
          .evaluate()
          .length;
      gestureTotal += find
          .descendant(
            of: find.byType(MushafPageCard),
            matching: find.byType(GestureDetector),
          )
          .evaluate()
          .length;
      var paragraphs = 0;
      void count(RenderObject r) {
        if (r is RenderParagraph) paragraphs++;
        r.visitChildren(count);
      }

      count(root.renderObject!);
      paragraphTotal += paragraphs;

      // 2. The same page from nothing again (new elements, font already used once).
      await t.pumpWidget(const SizedBox());
      final s1 = Stopwatch()..start();
      await t.pumpWidget(_host(tick, size, page));
      s1.stop();
      fresh.add(ms(s1));

      // 3. Rebuild with nothing changed: what every setState of the reader costs the page.
      for (var i = 0; i < 20; i++) {
        tick.value++;
        final s = Stopwatch()..start();
        await t.pump();
        s.stop();
        warm.add(ms(s));
      }

      // 3b. What-if for the fix: the screen rebuilds but hands the page the same widget instance as before (the page keeps
      // its widget in its State and makes a new one only when its data, look, size or highlight change).
      final cached = page();
      final probe = RebuildProbe()..start();
      probe.phase = 'cached';
      await t.pumpWidget(_host(tick, size, () => cached));
      probe.phase = 'cached-ticks';
      for (var i = 0; i < 20; i++) {
        tick.value++;
        final s = Stopwatch()..start();
        await t.pump();
        s.stop();
        cachedTicks.add(ms(s));
      }
      cachedRebuilds += probe.count('cached-ticks', 'MushafPage');
      probe.stop();

      // 4. Relayout: the page gets another width, so every word is laid out again (upper bound of the first layout).
      for (var i = 0; i < 6; i++) {
        size = Size(i.isEven ? 400 : 412, _box.height);
        final s = Stopwatch()..start();
        await t.pumpWidget(_host(tick, size, page));
        s.stop();
        relayout.add(ms(s));
      }
    }

    final n = pages.length;
    motionLog(
      'M3 elements per page (mean of $n pages): ${elementsTotal ~/ n} elements, '
      '${textTotal ~/ n} Text, ${gestureTotal ~/ n} GestureDetector, ${paragraphTotal ~/ n} RenderParagraph',
    );
    motionLog(
      'M3 first build of a page (new font family, build+layout+paint): ${MotionStats(cold)}',
    );
    motionLog(
      'M3 build again from nothing (font already used): ${MotionStats(fresh)}',
    );
    motionLog(
      'M3 rebuild with nothing changed (new widgets, same data), one per setState: ${MotionStats(warm)}',
    );
    motionLog(
      'M3 relayout of every word (width changes): ${MotionStats(relayout)}',
    );
    motionLog(
      'M3 what-if, the page gets the same widget instance on every screen rebuild: ${MotionStats(cachedTicks)}; '
      'MushafPage rebuilds in ${cachedTicks.length} ticks: $cachedRebuilds',
    );
    motionLog(
      'M3 ratio rebuild-with-nothing-changed / build-from-nothing: '
      '${(MotionStats(warm).median / MotionStats(fresh).median).toStringAsFixed(2)}',
    );
    // The typical page rebuild stays under 50 ms in the slow test VM. The median is used, not the maximum: other
    // test runs on the same machine slow single samples down (the baseline run saw one 52 ms sample).
    expect(MotionStats(warm).median, lessThan(50));
    expect(MotionStats(fresh).median, lessThan(500));
    expect(
      cachedRebuilds,
      0,
      reason: 'an identical widget instance is not rebuilt',
    );
  });
}
