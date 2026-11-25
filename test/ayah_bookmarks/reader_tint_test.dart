// The tint through the reader (feature 013, task T036; spec FR-016, FR-022 to FR-027, SC-014, SC-016, SC-017; research D6):
// the words of the ayat that have an ayah bookmark of the current scope are drawn on the look's tint, word by word; another
// scope's bookmark and a page bookmark tint nothing; the temporary highlight replaces the tint while it lasts; the tint
// follows every change in the first frame after the reader knows of it; the Settings switch turns it off and on live; the
// shared page picture never carries it.
//
// No ayah crosses a page in this edition (the spec's correction of 2026-11-26): 2:282 fills page 48 alone and page 49 opens
// with 2:283, so 2:282 is tinted on page 48 and nothing of pages 47, 49 and 50 is.
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mushaf/ayah/ayah_ref.dart';
import 'package:mushaf/backup/backup_service.dart';
import 'package:mushaf/look/look_choice.dart';
import 'package:mushaf/mushaf/bookmark_strings.dart';
import 'package:mushaf/mushaf/page_font_loader.dart';
import 'package:mushaf/mushaf/page_look.dart';
import 'package:mushaf/render/page_renderer.dart';
import 'package:mushaf/search/ayah_target.dart';
import 'package:mushaf/theme.dart';
import 'package:mushaf/wirds/db.dart';
import 'package:mushaf/wirds/wird_repository.dart';
import 'package:drift/drift.dart' show driftRuntimeOptions;

import '../support/ayah_bookmark_harness.dart'
    show ayahBookmarkRow, byKey, seedAyahBookmark;
import '../support/reader_harness.dart' show settleReader;
import '../support/reader_search_harness.dart' show popIndexWith;
import '../support/tint_harness.dart';

const a282 = AyahRef(2, 282); // the whole of page 48
const a283 = AyahRef(2, 283); // page 49, with 284, 285 and 286
const a284 = AyahRef(2, 284);
const a285 = AyahRef(2, 285);

const second = WirdDraft(
  name: 'الثاني',
  type: WirdType.reading,
  startPage: 49,
  dailyPages: 5,
  color: 0xFF1565C0,
);

Future<void> openList(WidgetTester t) async {
  await t.tap(
    find.descendant(of: byKey('bottom-bar'), matching: find.text('علامات')),
  );
  await settleReader(t);
}

/// Drives [work] (an offscreen render: it needs frames and the engine's real time) to its end.
Future<T> resolve<T>(WidgetTester t, Future<T> Function() work) async {
  T? result;
  Object? error;
  var done = false;
  work().then(
    (v) {
      result = v;
      done = true;
    },
    onError: (Object e) {
      error = e;
      done = true;
    },
  );
  for (var i = 0; i < 600 && !done; i++) {
    await t.pump(const Duration(milliseconds: 16));
    await t.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
  }
  if (!done) fail('the render did not finish');
  if (error != null) fail('the render failed: $error');
  return result as T;
}

/// How many pixels of [rgba] are within [tolerance] of (r, g, b) on every channel.
int countPixels(List<int> rgba, int r, int g, int b, {int tolerance = 3}) {
  var n = 0;
  for (var i = 0; i < rgba.length; i += 4) {
    if ((rgba[i] - r).abs() <= tolerance &&
        (rgba[i + 1] - g).abs() <= tolerance &&
        (rgba[i + 2] - b).abs() <= tolerance) {
      n++;
    }
  }
  return n;
}

void main() {
  // The restore test makes its backup file from a second in-memory database.
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  group('scope (FR-022, SC-014)', () {
    // On page 49: 2:283 of the active wird, 2:284 of another wird, 2:285 general, and a page bookmark of every scope.
    Future<TintReader> reader(WidgetTester t, {bool browse = false}) =>
        pumpTintReader(
          t,
          startPage: 49,
          browseWithWird: browse,
          seed: (db, repo, meta, wirdId) async {
            final other = await repo.create(second);
            await seedAyahBookmark(db, meta, a283, wirdId: wirdId);
            await seedAyahBookmark(db, meta, a284, wirdId: other);
            await seedAyahBookmark(db, meta, a285);
            await repo.addBookmark(49, null, wirdId: wirdId);
            await repo.addBookmark(49, 'صفحة', wirdId: other);
            await repo.addBookmark(49, null);
          },
        );

    testWidgets('following a wird: exactly the active wird\'s ayah', (t) async {
      final r = await reader(t);
      expect(tintShownPage(t), '49');
      expect(find.text('اجعلها موضعي'), findsNothing, reason: 'wird mode');
      final want = await r.ids(t, 49, [a283]);
      expect(want, isNotEmpty);
      expect(r.tinted(t), want);
      expect(r.highlighted(t), isEmpty);
    });

    testWidgets('browsing with a wird: exactly the general ayah', (t) async {
      final r = await reader(t, browse: true);
      expect(tintShownPage(t), '49');
      expect(find.text('اجعلها موضعي'), findsOneWidget, reason: 'browse mode');
      expect(r.tinted(t), await r.ids(t, 49, [a285]));
    });

    testWidgets('no wird: exactly the general ayat, none for a page bookmark', (
      t,
    ) async {
      final r = await pumpTintReader(
        t,
        startPage: 49,
        noWird: true,
        seed: (db, repo, meta, wirdId) async {
          expect(wirdId, isNull);
          await seedAyahBookmark(db, meta, a285);
          await repo.addBookmark(49, null);
          await repo.addBookmark(50, 'صفحة');
        },
      );
      expect(tintShownPage(t), '49');
      expect(r.tinted(t), await r.ids(t, 49, [a285]));
      await goToPage(t, 50);
      expect(tintShownPage(t), '50');
      expect(
        r.tinted(t, skipOffstage: false),
        await r.ids(t, 49, [a285]),
        reason: 'page 50 has only a page bookmark: nothing of it is tinted (page 49 stays built beside it)',
      );
      expect(r.tinted(t), isEmpty);
    });

    testWidgets('a page bookmark alone tints nothing, in the wird\'s scope', (
      t,
    ) async {
      final r = await pumpTintReader(
        t,
        startPage: 49,
        seed: (db, repo, meta, wirdId) async {
          await repo.addBookmark(49, null, wirdId: wirdId);
          await repo.addBookmark(48, 'صفحة', wirdId: wirdId);
        },
      );
      expect(r.tinted(t, skipOffstage: false), isEmpty);
    });
  });

  group('which words (FR-016, FR-025, SC-014)', () {
    testWidgets(
      '2:282 is tinted on page 48, every word of it, and nothing on pages 47, 49 and 50',
      (t) async {
        final r = await pumpTintReader(
          t,
          startPage: 48,
          noWird: true,
          seed: (db, repo, meta, wirdId) => seedAyahBookmark(db, meta, a282),
        );
        final page48 = await r.allIds(t, 48);
        expect(await r.ids(t, 48, [a282]), page48, reason: 'it fills page 48');
        expect(r.tinted(t), page48);
        expect(
          r.tinted(t, skipOffstage: false),
          page48,
          reason: 'pages 47 and 49, built beside it, have no tinted word',
        );
        expect(await r.ids(t, 47, [a282]), isEmpty);
        expect(await r.ids(t, 49, [a282]), isEmpty);
        await goToPage(t, 49);
        expect(tintShownPage(t), '49');
        expect(r.tinted(t), isEmpty, reason: 'nothing on page 49');
        expect(
          r.tinted(t, skipOffstage: false),
          page48,
          reason: 'nor on page 50, built beside it; page 48 keeps its own',
        );
        await goToPage(t, 50);
        expect(r.tinted(t), isEmpty, reason: 'nothing on page 50');
        await goToPage(t, 48);
        expect(r.tinted(t), page48, reason: 'back on page 48');
        expect(r.unexpectedErrors, isEmpty);
      },
    );

    testWidgets(
      'two ayat that follow each other are tinted separately, word by word',
      (t) async {
        final r = await pumpTintReader(
          t,
          startPage: 49,
          seed: (db, repo, meta, wirdId) async {
            await seedAyahBookmark(db, meta, a283, wirdId: wirdId);
            await seedAyahBookmark(db, meta, a284, wirdId: wirdId);
          },
        );
        final first = await r.ids(t, 49, [a283]);
        final next = await r.ids(t, 49, [a284]);
        expect(first.intersection(next), isEmpty);
        // wordsOn checks that every tinted box holds exactly one word and has the word decoration's radius.
        expect(r.tinted(t), {...first, ...next});
        final boxes = t
            .widgetList<DecoratedBox>(find.byType(DecoratedBox))
            .where(
              (b) =>
                  b.decoration is BoxDecoration &&
                  (b.decoration as BoxDecoration).color == r.tintColor,
            );
        expect(
          boxes,
          hasLength(first.length + next.length),
          reason: 'one box per word, no band across words or ayat',
        );
        // The last word of the first ayah (its end marker) and the first word of the next have their own boxes.
        final end = (first.toList()..sort()).last;
        final start = (next.toList()..sort()).first;
        expect(start, end + 1);
        final endBox = t.getRect(byKey('w$end'));
        final startBox = t.getRect(byKey('w$start'));
        expect(endBox.overlaps(startBox), isFalse);
      },
    );

    testWidgets('Night Reader draws its own tint colour', (t) async {
      final r = await pumpTintReader(
        t,
        startPage: 49,
        look: LookChoice.night,
        seed: (db, repo, meta, wirdId) =>
            seedAyahBookmark(db, meta, a283, wirdId: wirdId),
      );
      expect(r.tintColor, PageLook.night.bookmarkTint);
      expect(r.tintColor, isNot(PageLook.emerald.bookmarkTint));
      expect(r.tinted(t), await r.ids(t, 49, [a283]));
      expect(wordsOn(t, PageLook.emerald.bookmarkTint), isEmpty);
    });
  });

  group('the temporary highlight replaces the tint (FR-023)', () {
    testWidgets(
      'a long press: highlight in place of the tint, the tint is back '
      'after the sheet closes',
      (t) async {
        final r = await pumpTintReader(
          t,
          startPage: 49,
          seed: (db, repo, meta, wirdId) async {
            await seedAyahBookmark(db, meta, a283, wirdId: wirdId);
            await seedAyahBookmark(db, meta, a284, wirdId: wirdId);
          },
        );
        final first = await r.ids(t, 49, [a283]);
        final next = await r.ids(t, 49, [a284]);
        expect(r.tinted(t), {...first, ...next});
        await r.longPressAyah(t, a283, page: 49);
        expect(ayahBookmarkRow, findsOneWidget, reason: 'the sheet is open');
        expect(r.highlighted(t), first);
        expect(r.tinted(t), next, reason: 'the other ayah keeps its tint');
        r.navigator.currentState!.pop();
        await settleReader(t);
        expect(ayahBookmarkRow, findsNothing);
        expect(r.highlighted(t), isEmpty);
        expect(r.tinted(t), {...first, ...next});
      },
    );

    for (final from in ['the list', 'a search result']) {
      testWidgets(
        'opened from $from: highlight in place of the tint, the tint is back '
        'after the first touch',
        (t) async {
          late int rowId;
          final r = await pumpTintReader(
            t,
            startPage: 52,
            alsoLoad: const [49],
            noWird: true,
            seed: (db, repo, meta, wirdId) async {
              rowId = await seedAyahBookmark(db, meta, a283);
              await seedAyahBookmark(db, meta, a284);
            },
          );
          final first = await r.ids(t, 49, [a283]);
          final next = await r.ids(t, 49, [a284]);
          if (from == 'the list') {
            await openList(t);
            await t.tap(byKey('bookmark-$rowId'));
            await settleReader(t);
          } else {
            await popIndexWith(t, const AyahTarget(a283, 49));
          }
          expect(tintShownPage(t), '49');
          expect(r.highlighted(t), first);
          expect(r.tinted(t), next);
          await t.tapAt(t.getCenter(find.byType(PageView)));
          await t.pump(const Duration(milliseconds: 400));
          expect(r.highlighted(t), isEmpty);
          expect(r.tinted(t), {...first, ...next});
        },
      );
    }
  });

  group('the first frame after a change (FR-026, SC-016)', () {
    testWidgets('an add, then its undo', (t) async {
      final r = await pumpTintReader(t, startPage: 49);
      final want = await r.ids(t, 49, [a283]);
      expect(r.tinted(t), isEmpty);
      await r.longPressAyah(t, a283, page: 49);
      await r.expectFirstFrame(
        t,
        action: () => t.tap(ayahBookmarkRow),
        marks: {a283},
        expected: want,
      );
      expect(await r.bookmarks(t), hasLength(1));
      expect(r.highlighted(t), isEmpty);
      await r.expectFirstFrame(
        t,
        action: () => t.tap(find.text(kBookmarkUndo)),
        marks: {},
        expected: {},
      );
      expect(await r.bookmarks(t), isEmpty);
    });

    testWidgets('a removal, then its undo', (t) async {
      final r = await pumpTintReader(
        t,
        startPage: 49,
        seed: (db, repo, meta, wirdId) async {
          await seedAyahBookmark(db, meta, a283, wirdId: wirdId);
          await seedAyahBookmark(db, meta, a285, wirdId: wirdId);
        },
      );
      final removed = await r.ids(t, 49, [a283]);
      final kept = await r.ids(t, 49, [a285]);
      expect(r.tinted(t), {...removed, ...kept});
      await r.longPressAyah(t, a283, page: 49);
      await r.expectFirstFrame(
        t,
        action: () => t.tap(ayahBookmarkRow),
        marks: {a285},
        expected: kept,
      );
      await r.expectFirstFrame(
        t,
        action: () => t.tap(find.text(kBookmarkUndo)),
        marks: {a283, a285},
        expected: {...removed, ...kept},
      );
    });

    testWidgets('a delete from the list sheet (the reader reads again when the '
        'sheet closes)', (t) async {
      late int rowId;
      final r = await pumpTintReader(
        t,
        startPage: 49,
        seed: (db, repo, meta, wirdId) async {
          rowId = await seedAyahBookmark(db, meta, a283, wirdId: wirdId);
          await seedAyahBookmark(db, meta, a285, wirdId: wirdId);
        },
      );
      final kept = await r.ids(t, 49, [a285]);
      await openList(t);
      await t.drag(byKey('bookmark-$rowId'), const Offset(-500, 0));
      await settleReader(t);
      expect(await r.bookmarks(t), hasLength(1));
      await r.expectFirstFrame(
        t,
        action: () async => r.navigator.currentState!.pop(),
        marks: {a285},
        expected: kept,
      );
    });

    testWidgets('a restore (the reader reloads)', (t) async {
      // A backup of another app state: the wird on page 49 with 2:285 bookmarked, not 2:283.
      final json = await t.runAsync(() async {
        final other = AppDatabase(NativeDatabase.memory());
        final otherRepo = WirdRepository(other);
        await otherRepo.ensureDefaults();
        final id = (await otherRepo.activeWird())!.id;
        await otherRepo.setPage(id, 49);
        await otherRepo.toggleAyahBookmark(a285, page: 49, wirdId: id);
        final out = await BackupService(other).exportJson();
        await other.close();
        return out;
      });
      final r = await pumpTintReader(
        t,
        startPage: 49,
        withBackup: true,
        seed: (db, repo, meta, wirdId) =>
            seedAyahBookmark(db, meta, a283, wirdId: wirdId),
      );
      expect(r.tinted(t), await r.ids(t, 49, [a283]));
      r.files.toPick = json;
      await t.tap(byKey('open-settings'));
      await settleReader(t);
      final import = byKey('backup-import');
      await t.scrollUntilVisible(
        import,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await t.tap(import);
      await settleReader(t);
      await r.expectFirstFrame(
        t,
        action: () => t.tap(byKey('import-confirm')),
        marks: {a285},
        expected: await r.ids(t, 49, [a285]),
        skipOffstage: false,
      );
      expect(import, findsNothing, reason: 'back on the reader');
      expect(tintShownPage(t), '49');
      expect(r.tinted(t), await r.ids(t, 49, [a285]));
    });

    testWidgets('a wird switch', (t) async {
      late int other;
      final r = await pumpTintReader(
        t,
        startPage: 49,
        seed: (db, repo, meta, wirdId) async {
          other = await repo.create(second);
          await seedAyahBookmark(db, meta, a283, wirdId: wirdId);
          await seedAyahBookmark(db, meta, a284, wirdId: other);
        },
      );
      expect(r.tinted(t), await r.ids(t, 49, [a283]));
      await t.tap(
        find.descendant(of: byKey('bottom-bar'), matching: find.text('أوراد')),
      );
      await settleReader(t);
      await r.expectFirstFrame(
        t,
        action: () => t.tap(byKey('wird-$other')),
        marks: {a284},
        expected: await r.ids(t, 49, [a284]),
        skipOffstage: false,
      );
      expect(tintShownPage(t), '49');
      expect(r.tinted(t), await r.ids(t, 49, [a284]));
    });

    testWidgets('a wird deletion: its bookmarks are no longer the scope\'s', (
      t,
    ) async {
      late int active;
      final r = await pumpTintReader(
        t,
        startPage: 49,
        seed: (db, repo, meta, wirdId) async {
          active = wirdId!;
          final other = await repo.create(second);
          await seedAyahBookmark(db, meta, a283, wirdId: wirdId);
          await seedAyahBookmark(db, meta, a284, wirdId: other);
        },
      );
      expect(r.tinted(t), await r.ids(t, 49, [a283]));
      // The other wird becomes the active one; the deleted wird's bookmark became general.
      await r.expectFirstFrame(
        t,
        action: () async => t.runAsync(() => r.repo.delete(active)),
        marks: {a284},
        expected: await r.ids(t, 49, [a284]),
      );
      expect(tintShownPage(t), '49');
      final rows = await r.bookmarks(t);
      expect(rows.where((b) => b.ayah == 283).single.wirdId, isNull);
    });

    testWidgets('the last wird deleted: its bookmarks became general and are '
        'the scope\'s', (t) async {
      late int active;
      final r = await pumpTintReader(
        t,
        startPage: 49,
        seed: (db, repo, meta, wirdId) async {
          active = wirdId!;
          await repo.setLastViewedPage(49);
          await seedAyahBookmark(db, meta, a283, wirdId: wirdId);
          await seedAyahBookmark(db, meta, a285);
        },
      );
      expect(r.tinted(t), await r.ids(t, 49, [a283]));
      await r.expectFirstFrame(
        t,
        action: () async => t.runAsync(() => r.repo.delete(active)),
        marks: {a283, a285},
        expected: await r.ids(t, 49, [a283, a285]),
      );
      expect(tintShownPage(t), '49');
    });
  });

  group('the Settings switch (FR-024, SC-017)', () {
    testWidgets(
      'off tints nothing on any page, on again returns without a restart',
      (t) async {
        final r = await pumpTintReader(
          t,
          startPage: 49,
          seed: (db, repo, meta, wirdId) async {
            await seedAyahBookmark(db, meta, a282, wirdId: wirdId);
            await seedAyahBookmark(db, meta, a283, wirdId: wirdId);
          },
        );
        final all = {
          ...await r.ids(t, 48, [a282]),
          ...await r.ids(t, 49, [a283]),
        };
        expect(r.tinted(t, skipOffstage: false), all);
        await t.runAsync(() => r.tint.set(false));
        await t.pump();
        expect(r.tinted(t, skipOffstage: false), isEmpty, reason: 'off');
        // Everything else works as with it on: a new bookmark is made and still nothing is tinted.
        await r.longPressAyah(t, a284, page: 49);
        expect(r.highlighted(t), await r.ids(t, 49, [a284]));
        await t.tap(ayahBookmarkRow);
        await settleReader(t);
        expect(await r.bookmarks(t), hasLength(3));
        expect(r.tinted(t, skipOffstage: false), isEmpty);
        await t.runAsync(() => r.tint.set(true));
        await t.pump();
        expect(r.tinted(t, skipOffstage: false), {
          ...all,
          ...await r.ids(t, 49, [a284]),
        }, reason: 'on again, no restart');
      },
    );

    testWidgets('a reader opened with the switch off tints nothing', (t) async {
      final r = await pumpTintReader(
        t,
        startPage: 49,
        seed: (db, repo, meta, wirdId) async {
          await seedAyahBookmark(db, meta, a283, wirdId: wirdId);
          await repo.setAyahTint(false);
        },
      );
      expect(r.tint.enabled, isFalse);
      expect(r.tinted(t, skipOffstage: false), isEmpty);
      await t.runAsync(() => r.tint.set(true));
      await t.pump();
      expect(r.tinted(t), await r.ids(t, 49, [a283]));
    });
  });

  group('the shared page picture (FR-027)', () {
    testWidgets('the picture of a tinted page carries no tint', (t) async {
      final r = await pumpTintReader(
        t,
        startPage: 48,
        seed: (db, repo, meta, wirdId) =>
            seedAyahBookmark(db, meta, a282, wirdId: wirdId),
      );
      expect(r.tinted(t), await r.allIds(t, 48), reason: 'tinted on screen');
      final renderer = OffscreenPageRenderer(
        overlay: () => r.navigator.currentState!.overlay!,
        mushaf: r.mushaf,
        fonts: PageFontLoader(),
      );
      final img = await resolve(
        t,
        () => renderer.renderRgba(48, PageLook.screen, 1),
      );
      // The tint blended on the ivory paper is (213, 225, 208) (research D6).
      expect(
        countPixels(img.rgba, 213, 225, 208),
        0,
        reason: 'a picture never carries the tint',
      );
      final paper = AppColors.paper;
      expect(
        countPixels(
          img.rgba,
          (paper.r * 255).round(),
          (paper.g * 255).round(),
          (paper.b * 255).round(),
        ),
        greaterThan(img.width * img.height ~/ 4),
        reason: 'the page is drawn on its bare paper',
      );
    });
  });
}
