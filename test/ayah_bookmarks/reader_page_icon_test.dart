// The page icon of feature 006 keeps its own meaning (feature 013, task T026; spec FR-011, SC-012, SC-009): it shows and
// toggles PAGE bookmarks of the scope only. An ayah bookmark on the page neither fills it nor is deleted by it, in wird
// mode and in browse mode, and «تراجع» brings back exactly the page bookmark it removed. Another scope's bookmarks never
// count.
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mushaf/ayah/ayah_ref.dart';
import 'package:mushaf/mushaf/bookmark_strings.dart';
import 'package:mushaf/wirds/db.dart';
import 'package:mushaf/wirds/wird_repository.dart';

import '../support/ayah_bookmark_harness.dart';
import '../support/reader_harness.dart' show settleReader;

const baqarah282 = AyahRef(2, 282);

bool iconFilled(WidgetTester t) {
  final icons = t.widgetList<Icon>(
    find.descendant(of: byKey('bookmark-button'), matching: find.byType(Icon)),
  );
  final glyphs = {for (final i in icons) i.icon};
  expect(glyphs, hasLength(1));
  return glyphs.single == Icons.bookmark_added;
}

Future<void> tapIcon(WidgetTester t) async {
  await t.tap(byKey('bookmark-button'));
  await settleReader(t);
}

void main() {
  for (final mode in ['wird', 'browse']) {
    group(mode, () {
      Future<AyahBookmarkReader> open(
        WidgetTester t,
        Future<void> Function(
          AppDatabase db,
          WirdRepository repo,
          int? scope,
          int? otherWird,
        )
        seed,
      ) => pumpAyahBookmarkReader(
        t,
        startPage: 48,
        browseWithWird: mode == 'browse',
        seed: (db, repo, meta, wirdId) async {
          final other = await repo.create(
            const WirdDraft(
              name: 'الثاني',
              type: WirdType.reading,
              dailyPages: 5,
              color: 0xFF1565C0,
            ),
          );
          await seed(db, repo, mode == 'browse' ? null : wirdId, other);
        },
      );

      testWidgets(
        'only an ayah bookmark of the scope on the page: the icon is outlined; a tap adds a page bookmark',
        (t) async {
          late Bookmark ayah;
          final r = await open(t, (db, repo, scope, other) async {
            final meta = await realMeta();
            await seedAyahBookmark(
              db,
              meta,
              baqarah282,
              wirdId: scope,
              note: 'أراجع هنا',
            );
            ayah = (await db.select(db.bookmarks).get()).single;
          });
          expect(shownPage(t), '48');
          expect(iconFilled(t), isFalse);
          await tapIcon(t);
          expect(iconFilled(t), isTrue);
          final rows = await r.bookmarks(t);
          expect(rows, hasLength(2));
          expect(
            rows.first,
            ayah,
            reason: 'the ayah bookmark and its note are untouched',
          );
          final page = rows.last;
          expect(
            (page.page, page.surah, page.ayah, page.note),
            (48, null, null, null),
          );
        },
      );

      testWidgets(
        'a page and an ayah bookmark: a tap removes only the page bookmark, «تراجع» brings back exactly it',
        (t) async {
          late List<Bookmark> before;
          final r = await open(t, (db, repo, scope, other) async {
            final meta = await realMeta();
            await seedAyahBookmark(
              db,
              meta,
              baqarah282,
              wirdId: scope,
              note: 'أراجع هنا',
            );
            await repo.addBookmark(48, 'صفحة', wirdId: scope);
            before = await db.select(db.bookmarks).get();
          });
          expect(iconFilled(t), isTrue);
          await tapIcon(t);
          expect(iconFilled(t), isFalse);
          expect(await r.bookmarks(t), [
            before.first,
          ], reason: 'only the ayah bookmark is left');
          expect(message(kBookmarkRemoved(48)), findsOneWidget);
          await t.tap(find.text(kBookmarkUndo));
          await settleReader(t);
          expect(
            await r.bookmarks(t),
            before,
            reason: 'the same id, note, owner and time',
          );
          expect(iconFilled(t), isTrue);
        },
      );

      testWidgets('another scope\'s page and ayah bookmarks never count', (
        t,
      ) async {
        late List<Bookmark> before;
        final r = await open(t, (db, repo, scope, other) async {
          final meta = await realMeta();
          // Every scope that is not the reader's: the other wird, and the general bookmarks in wird mode or the active
          // wird's in browse mode.
          final active = (await repo.activeWird())!.id;
          for (final foreign in [other, scope == null ? active : null]) {
            await seedAyahBookmark(
              db,
              meta,
              baqarah282,
              wirdId: foreign,
              note: 'لغير هذا',
            );
            await repo.addBookmark(48, 'صفحة لغير هذا', wirdId: foreign);
          }
          before = await db.select(db.bookmarks).get();
        });
        expect(before, hasLength(4));
        expect(iconFilled(t), isFalse);
        await tapIcon(t);
        expect(iconFilled(t), isTrue);
        final rows = await r.bookmarks(t);
        expect(
          rows.take(4),
          before,
          reason: 'the other scopes\' rows are untouched',
        );
        expect(rows, hasLength(5));
        await tapIcon(t);
        expect(iconFilled(t), isFalse);
        expect(await r.bookmarks(t), before);
      });
    });
  }
}
