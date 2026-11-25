// Opening an ayah bookmark from «علامات» (feature 013, task T024; spec FR-012, SC-005; research D10): the sheet closes, the
// page where the ayah begins is shown in browse mode (the wird does not move) with exactly that ayah's words highlighted by
// the search's own mechanism and brought into view; the first touch clears the highlight; a page row jumps as before.
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mushaf/ayah/ayah_ref.dart';
import 'package:mushaf/mushaf/models.dart';
import 'package:mushaf/mushaf/mushaf_repository.dart';
import 'package:mushaf/mushaf/page_look.dart';

import '../support/ayah_bookmark_harness.dart';
import '../support/motion_probe.dart' show FileBundle;
import '../support/reader_harness.dart' show settleReader;

/// The ids of the words drawn with the highlight.
Set<int> highlightedIds(WidgetTester t) {
  final out = <int>{};
  for (final e in find.byType(DecoratedBox).evaluate()) {
    final d = (e.widget as DecoratedBox).decoration;
    if (d is! BoxDecoration || d.color != PageLook.screen.highlight) continue;
    for (final text
        in find
            .descendant(
              of: find.byElementPredicate((x) => identical(x, e)),
              matching: find.byType(Text),
            )
            .evaluate()) {
      final key = text.widget.key;
      if (key is ValueKey<String> && key.value.startsWith('w')) {
        out.add(int.parse(key.value.substring(1)));
      }
    }
  }
  return out;
}

/// Page [page] read from the project's assets by its own repository, so nothing the reader started is awaited.
Future<PageData> pageWords(WidgetTester t, int page) async =>
    (await t.runAsync(() => MushafRepository(FileBundle()).loadPage(page)))!;

Future<void> openList(WidgetTester t) async {
  await t.tap(
    find.descendant(of: byKey('bottom-bar'), matching: find.text('علامات')),
  );
  await settleReader(t);
}

void main() {
  const baqarah282 = AyahRef(2, 282);
  late int ayahId;
  late int pageId;

  Future<AyahBookmarkReader> reader(WidgetTester t, {int startPage = 50}) =>
      pumpAyahBookmarkReader(
        t,
        startPage: startPage,
        alsoLoad: const [48, 77],
        seed: (db, repo, meta, wirdId) async {
          pageId = await repo.addBookmark(77, null, wirdId: wirdId);
          ayahId = await seedAyahBookmark(
            db,
            meta,
            baqarah282,
            wirdId: wirdId,
            at: DateTime(2099),
          );
        },
      );

  testWidgets(
    'an ayah row shows its page in browse mode with exactly its words highlighted, in view',
    (t) async {
      final r = await reader(t);
      final wirdBefore = (await t.runAsync(() => r.repo.activeWird()))!;
      await openList(t);
      await t.tap(byKey('bookmark-$ayahId'));
      await settleReader(t);
      expect(byKey('bookmark-list'), findsNothing, reason: 'the sheet closed');
      expect(shownPage(t), '48');
      expect(find.text('اجعلها موضعي'), findsOneWidget, reason: 'browse mode');
      final wirdAfter = (await t.runAsync(() => r.repo.activeWird()))!;
      expect(
        wirdAfter.currentPage,
        wirdBefore.currentPage,
        reason: 'the wird did not move',
      );
      final data = await pageWords(t, 48);
      final ids = wordIdsOfAyah(data, baqarah282);
      expect(ids, isNotEmpty);
      expect(highlightedIds(t), ids);
      final pager = t.getRect(find.byType(PageView));
      final first = t.getRect(byKey('w${(ids.toList()..sort()).first}'));
      expect(pager.contains(first.center), isTrue, reason: 'brought into view');
    },
  );

  testWidgets(
    'on the page already shown only the highlight and the reveal happen',
    (t) async {
      await reader(t, startPage: 48);
      await openList(t);
      await t.tap(byKey('bookmark-$ayahId'));
      await settleReader(t);
      expect(shownPage(t), '48');
      expect(find.text('اجعلها موضعي'), findsNothing, reason: 'the mode stays');
      expect(
        highlightedIds(t),
        wordIdsOfAyah(await pageWords(t, 48), baqarah282),
      );
    },
  );

  testWidgets('the first touch clears the highlight', (t) async {
    await reader(t);
    await openList(t);
    await t.tap(byKey('bookmark-$ayahId'));
    await settleReader(t);
    expect(highlightedIds(t), isNotEmpty);
    await t.tapAt(t.getCenter(find.byType(PageView)));
    await t.pump(const Duration(milliseconds: 400));
    expect(highlightedIds(t), isEmpty);
  });

  testWidgets('a page row still jumps to its page, with no highlight', (
    t,
  ) async {
    await reader(t);
    await openList(t);
    await t.tap(byKey('bookmark-$pageId'));
    await settleReader(t);
    expect(shownPage(t), '77');
    expect(highlightedIds(t), isEmpty);
  });
}
