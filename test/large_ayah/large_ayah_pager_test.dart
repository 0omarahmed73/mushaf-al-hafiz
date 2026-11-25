// The anchored pager of the large-ayah view (feature 015, research D5).
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mushaf/ayah/ayah_ref.dart';
import 'package:mushaf/large_ayah/large_ayah_pager.dart';
import 'package:mushaf/large_ayah/page_screens.dart';
import 'package:mushaf/large_ayah/screen_layout.dart';
import 'package:mushaf/large_ayah/screen_navigator.dart';
import 'package:mushaf/mushaf/models.dart';

import '../support/test_meta.dart';

/// Page p has 2 screens (3 on page 5 when [count] is 1), each one ayah of Al-Baqarah numbered from the page:
/// page p screen i holds 2:(10p + i + 1).
class _Source implements ScreenSource {
  _Source(this.count);

  final int count;

  @override
  Future<List<LargeScreen>> screensOf(int page) async {
    final n = page == 5 && count == 1 ? 3 : 2;
    return [
      for (var i = 0; i < n; i++)
        LargeScreen(
          page: page,
          items: [
            AyahItem(AyahRef(2, (10 * page + i + 1) % 286 + 1), [
              [MushafWord(id: page * 10 + i, key: '2:1:1', glyph: 'x', surah: 2, ayah: (10 * page + i + 1) % 286 + 1)],
            ]),
          ],
        ),
    ];
  }
}

int _pageOf(AyahRef a) => ((a.ayah - 2) ~/ 10).clamp(1, 604);

class _Probe {
  final List<LargeScreen> shown = [];
  int taps = 0;
  int pastEnd = 0;
}

Future<_Probe> _pump(WidgetTester t, LargeTarget target, {int count = 1, Key? key}) async {
  final probe = _Probe();
  await t.pumpWidget(_Host(key: key, target: target, count: count, probe: probe));
  await t.pumpAndSettle();
  return probe;
}

class _Host extends StatelessWidget {
  const _Host({super.key, required this.target, required this.count, required this.probe});

  final LargeTarget target;
  final int count;
  final _Probe probe;

  @override
  Widget build(BuildContext context) => MaterialApp(
    home: SizedBox(
      width: 400,
      height: 700,
      child: LargeAyahPager(
        sourceFor: (_) => _Source(count),
        layoutKey: count,
        pageOfAyah: _pageOf,
        meta: testMeta(),
        factor: 2.0,
        target: target,
        onScreenShown: probe.shown.add,
        onTap: () => probe.taps++,
        onPastEnd: () => probe.pastEnd++,
      ),
    ),
  );
}

String _header(WidgetTester t) => t.widget<Text>(find.byKey(const ValueKey('large-header'))).data!;

void main() {
  testWidgets('starts at its target and reports the screen', (t) async {
    final probe = await _pump(t, const LargeTarget.page(7));
    expect(probe.shown.single.page, 7);
    expect(_header(t), contains('صفحة ٧'));
  });

  testWidgets('a left-to-right swipe brings the next screen in from the left, across pages', (t) async {
    final probe = await _pump(t, const LargeTarget.page(7));
    final before = t.getCenter(find.byKey(const ValueKey('large-header')));
    await t.drag(find.byType(LargeAyahPager), const Offset(600, 0));
    await t.pumpAndSettle();
    expect(probe.shown.last.page, 7);
    expect(probe.shown.last.ayat.single, const AyahRef(2, 73));
    await t.drag(find.byType(LargeAyahPager), const Offset(600, 0));
    await t.pumpAndSettle();
    expect(probe.shown.last.page, 8, reason: 'from the last screen of 7 to the first of 8');
    expect(before.dx, greaterThan(0));
    await t.drag(find.byType(LargeAyahPager), const Offset(-600, 0));
    await t.pumpAndSettle();
    expect(probe.shown.last.page, 7);
    expect(probe.shown.last.ayat.single, const AyahRef(2, 73));
  });

  testWidgets('the incoming screen comes from the left side during the swipe', (t) async {
    await _pump(t, const LargeTarget.page(7));
    final gesture = await t.startGesture(const Offset(100, 300));
    await gesture.moveBy(const Offset(30, 0));
    await t.pump();
    await gesture.moveBy(const Offset(150, 0));
    await t.pump();
    Finder header(String digits) => find.byWidgetPredicate(
      (w) => w is Text && w.key == const ValueKey('large-header') && w.data!.contains(digits),
      skipOffstage: false,
    );
    expect(t.getCenter(header('٧٢')).dx, greaterThan(400), reason: 'the shown screen moves right with the finger');
    expect(
      t.getCenter(header('٧٣')).dx,
      lessThan(t.getCenter(header('٧٢')).dx),
      reason: 'the next screen is on its left',
    );
    await gesture.up();
    await t.pumpAndSettle();
  });

  testWidgets('stops at the first screen of page 1', (t) async {
    final probe = await _pump(t, const LargeTarget.page(1));
    await t.drag(find.byType(LargeAyahPager), const Offset(-600, 0));
    await t.pumpAndSettle();
    expect(probe.shown.last.page, 1);
    expect(probe.shown.last.ayat.single, probe.shown.first.ayat.single);
  });

  testWidgets('past the last screen of page 604 it calls onPastEnd once', (t) async {
    final probe = await _pump(t, const LargeTarget.page(604));
    await t.drag(find.byType(LargeAyahPager), const Offset(600, 0));
    await t.pumpAndSettle();
    expect(probe.shown.last.page, 604);
    expect(probe.pastEnd, 0);
    await t.drag(find.byType(LargeAyahPager), const Offset(600, 0));
    await t.pumpAndSettle();
    expect(probe.shown.last.page, 604);
    expect(probe.pastEnd, 1);
  });

  testWidgets('an ayah target opens the screen that holds it', (t) async {
    final probe = await _pump(t, const LargeTarget.ayah(AyahRef(2, 53)));
    expect(probe.shown.last.page, 5);
    expect(probe.shown.last.ayat.single, const AyahRef(2, 53));
  });

  testWidgets('a new layout re-anchors at the same first ayah', (t) async {
    const key = ValueKey('host');
    final probe = await _pump(t, const LargeTarget.ayah(AyahRef(2, 53)), key: key);
    await t.pumpWidget(_Host(key: key, target: const LargeTarget.ayah(AyahRef(2, 53)), count: 2, probe: probe));
    await t.pumpAndSettle();
    expect(probe.shown.last.ayat.first, const AyahRef(2, 53));
    expect(_header(t), contains('٥٣'));
  });

  testWidgets('a tap calls onTap', (t) async {
    final probe = await _pump(t, const LargeTarget.page(7));
    await t.tap(find.byType(LargeAyahPager));
    expect(probe.taps, 1);
  });

  testWidgets('a new target with a new token re-anchors even to the same page', (t) async {
    const key = ValueKey('host');
    final probe = await _pump(t, const LargeTarget.page(7), key: key);
    await t.drag(find.byType(LargeAyahPager), const Offset(600, 0));
    await t.pumpAndSettle();
    await t.pumpWidget(_Host(key: key, target: const LargeTarget.page(7, token: 1), count: 1, probe: probe));
    await t.pumpAndSettle();
    expect(probe.shown.last.ayat.single, const AyahRef(2, 72));
  });

  test('the geometry used for the screens follows the box', () {
    final g = LargeGeometry(width: 400, height: 700, factor: 2);
    expect(g.fontSize, closeTo(2 * 368 / 16.2, 0.01));
  });
}
