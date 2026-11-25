// The rebuild budget of the tint (feature 013, task T037; spec FR-026, SC-010, SC-016; research D6): with 200 ayah bookmarks
// and the tint on, a page turn builds `MushafPage` at most once (the budget of feature 010 SC-003) and reads no bookmark from
// the database; a bookmark change on another page and a database answer that changes no tint build no page; adding or removing
// one bookmark builds only the page that shows it; a bars toggle builds none.
//
// The probe, the hand-driven swipe and the delayed database are those of test/support/motion_harness.dart; the reader is
// pumped through test/support/tint_harness.dart because the bookmarks must be in the database before the reader starts.
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mushaf/ayah/ayah_ref.dart';
import 'package:mushaf/mushaf/bookmark_strings.dart';
import 'package:mushaf/mushaf/mushaf_page.dart';

import '../support/ayah_bookmark_harness.dart' show ayahBookmarkRow, byKey;
import '../support/motion_harness.dart';
import '../support/motion_probe.dart';
import '../support/tint_harness.dart';

/// The pages around the start page: every ayah of them is bookmarked.
const List<int> around = [47, 48, 49, 50, 51, 52, 53, 54, 55];

class Probed {
  Probed(this.reader, this.motion, this.perPage);

  final TintReader reader;
  final MotionReader motion;

  /// `MushafPage` builds by page number while [counting].
  final Map<int, int> perPage;
  bool counting = false;

  RebuildProbe get probe => motion.probe;

  int get otherPages => perPage.entries
      .where((e) => e.key != 50)
      .fold<int>(0, (a, e) => a + e.value);
}

/// A reader on page 50 with 200 ayah bookmarks of its scope (every ayah of pages 47 to 55 among them), the tint on, and a
/// database that answers after 8 ms of test time, as the phone's does after a few frames.
Future<Probed> pumpProbed(WidgetTester t, {bool noWird = false}) async {
  var seeded = 0;
  final reader = await pumpTintReader(
    t,
    startPage: 50,
    noWird: noWird,
    interceptor: DelayedDatabase(const Duration(milliseconds: 8)),
    seed: (db, repo, meta, wirdId) async {
      seeded = (await seedManyAyahBookmarks(
        repo,
        wirdId,
        pages: around,
      )).length;
    },
  );
  expect(seeded, 200);
  expect(reader.tint.enabled, isTrue);
  expect(
    reader.tinted(t),
    await reader.allIds(t, 50),
    reason: 'the tint is on: every word of page 50 is tinted',
  );
  final probe = RebuildProbe()..start();
  addTearDown(probe.stop);
  final perPage = <int, int>{};
  final probed = Probed(reader, MotionReader(reader.repo, probe), perPage);
  // The probe counts by widget type; this adds which page was built.
  final byType = debugOnRebuildDirtyWidget;
  debugOnRebuildDirtyWidget = (element, builtOnce) {
    byType?.call(element, builtOnce);
    final w = element.widget;
    if (probed.counting && w is MushafPage) {
      perPage[w.data.page] = (perPage[w.data.page] ?? 0) + 1;
    }
  };
  return probed;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final noWird in [false, true]) {
    final mode = noWird ? 'browse mode' : 'wird mode';
    testWidgets(
      'a page turn builds MushafPage at most once and reads no bookmark, in $mode',
      (t) async {
        final p = await pumpProbed(t, noWird: noWird);
        for (var i = 1; i <= 3; i++) {
          final reads = p.reader.repo.bookmarkReads;
          final selects = p.reader.selects.count;
          await p.motion.swipeToNext(t, prefix: 'turn$i-');
          expect(
            p.probe.countAll('turn$i-', 'MushafPage'),
            lessThanOrEqualTo(1),
            reason:
                'turn $i: only the incoming page (or the next neighbour) may be built, none that is drawn',
          );
          expect(
            p.reader.repo.bookmarkReads,
            reads,
            reason: 'turn $i: the repository was not asked for the bookmarks',
          );
          expect(
            p.reader.selects.count,
            selects,
            reason: 'turn $i: no SELECT on the bookmarks table',
          );
          expect(tintShownPage(t), '${50 + i}');
          expect(
            p.reader.tinted(t),
            await p.reader.allIds(t, 50 + i),
            reason: 'turn $i: the page that came in is tinted',
          );
        }
      },
    );
  }

  testWidgets(
    'four taps on the page (bars hide, show, hide, show) build MushafPage 0 times',
    (t) async {
      final p = await pumpProbed(t);
      final centre = t.getCenter(find.byType(PageView));
      for (var i = 1; i <= 4; i++) {
        p.probe.phase = 'tap$i';
        await t.tapAt(centre);
        for (var f = 0; f < 20; f++) {
          await t.pump(const Duration(milliseconds: 16));
        }
      }
      p.probe.phase = null;
      expect(p.probe.countAll('tap', 'MushafPage'), 0);
      expect(p.reader.tinted(t), await p.reader.allIds(t, 50));
    },
  );

  testWidgets(
    'a database answer that changes no tint builds MushafPage 0 times',
    (t) async {
      final p = await pumpProbed(t);
      final reads = p.reader.repo.bookmarkReads;
      // A page bookmark through the top-bar icon, then its undo: two writes and two reads of the bookmarks, the same ayat.
      p.probe.phase = 'answer-icon';
      await t.tap(byKey('bookmark-button'));
      await settleMotion(t, rounds: 6);
      expect(find.text(kBookmarkAdded(50)), findsOneWidget);
      await t.tap(find.text(kBookmarkUndo));
      await settleMotion(t, rounds: 6);
      // «علامات» opened and closed with no change: the reader reads the bookmarks again and gets the same ayat.
      p.probe.phase = 'answer-list';
      await t.tap(
        find.descendant(of: byKey('bottom-bar'), matching: find.text('علامات')),
      );
      await settleMotion(t, rounds: 6);
      expect(byKey('bookmark-list'), findsOneWidget);
      p.reader.navigator.currentState!.pop();
      await settleMotion(t, rounds: 6);
      p.probe.phase = null;
      expect(
        p.reader.repo.bookmarkReads,
        greaterThanOrEqualTo(reads + 3),
        reason: 'the database did answer',
      );
      expect(p.probe.countAll('answer-', 'MushafPage'), 0);
      expect(p.reader.tinted(t), await p.reader.allIds(t, 50));
    },
  );

  testWidgets('a bookmark change on another page builds MushafPage 0 times', (
    t,
  ) async {
    final p = await pumpProbed(t);
    final far = (await p.reader.bookmarks(t)).where((b) => b.page >= 100).last;
    final changes = p.reader.repo.changes.length;
    await t.tap(
      find.descendant(of: byKey('bottom-bar'), matching: find.text('علامات')),
    );
    await settleMotion(t, rounds: 6);
    p.probe.phase = 'far';
    await t.drag(byKey('bookmark-${far.id}'), const Offset(-500, 0));
    await settleMotion(t, rounds: 8);
    p.reader.navigator.currentState!.pop();
    await settleMotion(t, rounds: 8);
    p.probe.phase = null;
    expect(await p.reader.bookmarks(t), hasLength(199));
    expect(
      p.reader.repo.changes.length,
      changes + 1,
      reason: 'the reader\'s set of tinted ayat did change',
    );
    expect(
      p.reader.repo.changes.last.marks,
      isNot(contains(AyahRef(far.surah!, far.ayah!))),
    );
    expect(p.probe.countAll('far', 'MushafPage'), 0);
    expect(p.reader.tinted(t), await p.reader.allIds(t, 50));
  });

  testWidgets(
    'removing one bookmark and adding it back build only the page that shows it',
    (t) async {
      final p = await pumpProbed(t);
      final page = await p.reader.page(t, 50);
      final first = page.lines.expand((l) => l.words).first;
      final ref = AyahRef(first.surah, first.ayah);
      final ayah = await p.reader.ids(t, 50, [ref]);
      final all = await p.reader.allIds(t, 50);
      expect(all.difference(ayah), isNotEmpty);

      // The removal goes through the ayah sheet: the long press's highlight comes and goes on the same page.
      p.counting = true;
      await p.reader.longPressAyah(t, ref, page: 50);
      await t.tap(ayahBookmarkRow);
      await settleMotion(t, rounds: 8);
      p.counting = false;
      expect(p.reader.tinted(t), all.difference(ayah), reason: 'removed');
      expect(p.otherPages, 0, reason: 'no other page was built: ${p.perPage}');
      expect(
        p.perPage[50],
        inInclusiveRange(1, 3),
        reason: 'page 50: the highlight on, and the highlight off with the tint gone (one build or two)',
      );

      // «تراجع» adds it back with no highlight involved: exactly one build of the page that shows it.
      p.perPage.clear();
      p.counting = true;
      await t.tap(find.text(kBookmarkUndo));
      await settleMotion(t, rounds: 8);
      p.counting = false;
      expect(p.reader.tinted(t), all, reason: 'added back');
      expect(p.perPage, {50: 1});
    },
  );
}
