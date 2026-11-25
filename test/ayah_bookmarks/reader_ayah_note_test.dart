// «ملاحظة للآية» end to end through the reader (feature 013, task T030; spec FR-021, FR-004, FR-019, SC-009, SC-013;
// data-model.md Bookmarks.note, AyahBookmarkChange.before): long press a word, tap the note row, type, save. The four saves
// (create, replace, clear, nothing), cancel, «تراجع» after each, the note in «علامات» and in a backup, the scope rule, and
// nothing of the wird moving.
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mushaf/ayah/ayah_ref.dart';
import 'package:mushaf/backup/backup_service.dart';
import 'package:mushaf/mushaf/ayah_bookmark_strings.dart';
import 'package:mushaf/mushaf/bookmark_strings.dart';
import 'package:mushaf/mushaf/page_look.dart';
import 'package:mushaf/wirds/ayah_bookmark_change.dart';
import 'package:mushaf/wirds/db.dart';
import 'package:mushaf/wirds/wird_repository.dart';

import '../support/ayah_bookmark_harness.dart';
import '../support/reader_harness.dart' show settleReader;

const baqarah282 = AyahRef(2, 282);
const surah = 'البقرة';
final seededAt = DateTime(2026, 11, 1, 8);
final Finder noteField = byKey('ayah-note-field');

/// Everything a note must leave as it was: the wirds (position, khatma count), today's portions and the settings.
Future<Object> wirdState(WidgetTester t, AyahBookmarkReader r) async =>
    (await t.runAsync(() async {
      final db = r.db;
      return [
        for (final w in await db.select(db.wirds).get()) w.toJson(),
        for (final d in await db.select(db.wirdDays).get()) d.toJson(),
        for (final s in await db.select(db.settings).get()) s.toJson(),
      ].toString();
    }))!;

/// The words drawn with the long press's highlight.
int highlighted(WidgetTester t) => t
    .widgetList<DecoratedBox>(find.byType(DecoratedBox))
    .where(
      (b) =>
          b.decoration is BoxDecoration &&
          (b.decoration as BoxDecoration).color == PageLook.screen.highlight,
    )
    .length;

/// The texts of the sheet's note row: its label, then the start of the note when there is one.
List<String?> noteRowTexts(WidgetTester t) => [
  for (final w in t.widgetList<Text>(
    find.descendant(of: ayahNoteRow, matching: find.byType(Text)),
  ))
    w.data,
];

/// Long presses 2:282 on page 48 and opens the note field from the sheet's row.
Future<void> openNote(WidgetTester t, AyahBookmarkReader r) async {
  await r.longPressAyah(t, baqarah282, page: 48);
  await t.tap(ayahNoteRow);
  await settleReader(t);
  expect(noteField, findsOneWidget);
}

/// Types [text] in the open note field and taps «حفظ».
Future<void> saveNote(WidgetTester t, String text) async {
  await t.enterText(noteField, text);
  await t.tap(byKey('ayah-note-save'));
  await settleReader(t);
}

Future<void> undo(WidgetTester t) async {
  await t.tap(find.text(kBookmarkUndo));
  await settleReader(t);
}

Future<void> openList(WidgetTester t) async {
  await t.tap(
    find.descendant(of: byKey('bottom-bar'), matching: find.text('علامات')),
  );
  await settleReader(t);
}

Future<int> secondWird(WirdRepository repo) => repo.create(
  const WirdDraft(
    name: 'الثاني',
    type: WirdType.reading,
    dailyPages: 5,
    color: 0xFF1565C0,
  ),
);

class FailingNoteRepo extends WirdRepository {
  FailingNoteRepo(super.db);

  @override
  Future<AyahBookmarkChange?> saveAyahNote(
    AyahRef ref, {
    required int page,
    int? wirdId,
    String? note,
  }) async => throw StateError('disk full');
}

void main() {
  for (final mode in ['wird', 'browse with a wird', 'no wird']) {
    testWidgets(
      '$mode: a note on an unbookmarked ayah creates one bookmark with it, owned by the scope; «تراجع» removes it',
      (t) async {
        final r = await pumpAyahBookmarkReader(
          t,
          startPage: 48,
          browseWithWird: mode == 'browse with a wird',
          noWird: mode == 'no wird',
        );
        expect(shownPage(t), '48');
        final state = await wirdState(t, r);
        final scope = mode == 'wird'
            ? (await t.runAsync(() => r.repo.activeWird()))!.id
            : null;
        await r.longPressAyah(t, baqarah282, page: 48);
        expect(noteRowTexts(t), [kAyahNoteLabel]);
        await t.tap(ayahNoteRow);
        await settleReader(t);
        expect(find.text(kAyahNoteTitle(surah, 282)), findsOneWidget);
        expect(t.widget<TextField>(noteField).controller!.text, '');
        expect(find.text(kAyahNoteHintNew), findsOneWidget);
        await saveNote(t, '  أراجع هنا  ');

        final b = (await r.bookmarks(t)).single;
        expect(
          (b.surah, b.ayah, b.page, b.note, b.wirdId),
          (2, 282, 48, 'أراجع هنا', scope),
        );
        expect(noteField, findsNothing, reason: 'the field closed');
        expect(ayahNoteRow, findsNothing, reason: 'the sheet closed');
        expect(highlighted(t), 0, reason: 'the ayah\'s highlight ended');
        final created = message(kAyahNoteCreated(surah, 282));
        expect(created, findsOneWidget);
        expect(
          t.getRect(created).bottom,
          lessThanOrEqualTo(t.getRect(byKey('bottom-bar')).top + 0.01),
          reason: 'above the bottom bar',
        );
        expect(shownPage(t), '48');
        expect(await wirdState(t, r), state);

        await undo(t);
        expect(await r.bookmarks(t), isEmpty, reason: '«تراجع» removed it');
        expect(await wirdState(t, r), state);
        await r.longPressAyah(t, baqarah282, page: 48);
        expect(noteRowTexts(t), [kAyahNoteLabel]);
      },
    );
  }

  testWidgets(
    'on a bookmarked ayah the note is replaced: no second row, id, page, owner and time unchanged; «تراجع» restores',
    (t) async {
      final r = await pumpAyahBookmarkReader(
        t,
        startPage: 48,
        seed: (db, repo, meta, wirdId) async {
          await seedAyahBookmark(
            db,
            meta,
            baqarah282,
            wirdId: wirdId,
            note: 'قديمة',
            at: seededAt,
          );
        },
      );
      final before = await r.bookmarks(t);
      final state = await wirdState(t, r);
      await r.longPressAyah(t, baqarah282, page: 48);
      expect(noteRowTexts(t), [kAyahNoteLabel, 'قديمة']);
      await t.tap(ayahNoteRow);
      await settleReader(t);
      expect(t.widget<TextField>(noteField).controller!.text, 'قديمة');
      expect(find.text(kAyahNoteHintExisting), findsOneWidget);
      await saveNote(t, 'جديدة');

      final after = (await r.bookmarks(t)).single;
      final was = before.single;
      expect(after.note, 'جديدة');
      expect(
        (
          after.id,
          after.page,
          after.wirdId,
          after.createdAt,
          after.surah,
          after.ayah,
        ),
        (was.id, was.page, was.wirdId, was.createdAt, was.surah, was.ayah),
      );
      expect(message(kAyahNoteSaved(surah, 282)), findsOneWidget);
      expect(ayahNoteRow, findsNothing, reason: 'the sheet closed');
      expect(await wirdState(t, r), state);

      await undo(t);
      expect(await r.bookmarks(t), before, reason: 'the previous note is back');
      expect(await wirdState(t, r), state);
    },
  );

  testWidgets(
    'a bookmark with no note gets one: «تم حفظ الملاحظة», still one row; «تراجع» takes the note away again',
    (t) async {
      final r = await pumpAyahBookmarkReader(
        t,
        startPage: 48,
        seed: (db, repo, meta, wirdId) async {
          await seedAyahBookmark(
            db,
            meta,
            baqarah282,
            wirdId: wirdId,
            at: seededAt,
          );
        },
      );
      final before = await r.bookmarks(t);
      await openNote(t, r);
      expect(find.text(kAyahNoteHintExisting), findsOneWidget);
      await saveNote(t, 'أراجع هنا');
      final after = (await r.bookmarks(t)).single;
      expect((after.id, after.note), (before.single.id, 'أراجع هنا'));
      expect(message(kAyahNoteSaved(surah, 282)), findsOneWidget);
      await undo(t);
      expect(await r.bookmarks(t), before);
    },
  );

  for (final empty in ['', '   ']) {
    testWidgets(
      'an empty save («$empty») clears the note and keeps the bookmark; «تراجع» brings the note back',
      (t) async {
        final r = await pumpAyahBookmarkReader(
          t,
          startPage: 48,
          seed: (db, repo, meta, wirdId) async {
            await seedAyahBookmark(
              db,
              meta,
              baqarah282,
              wirdId: wirdId,
              note: 'أراجع هنا',
              at: seededAt,
            );
          },
        );
        final before = await r.bookmarks(t);
        final state = await wirdState(t, r);
        await openNote(t, r);
        await saveNote(t, empty);

        final after = (await r.bookmarks(t)).single;
        final was = before.single;
        expect(after.note, isNull);
        expect(
          (
            after.id,
            after.page,
            after.wirdId,
            after.createdAt,
            after.surah,
            after.ayah,
          ),
          (was.id, was.page, was.wirdId, was.createdAt, was.surah, was.ayah),
        );
        expect(message(kAyahNoteRemoved(surah, 282)), findsOneWidget);
        expect(await wirdState(t, r), state);
        await undo(t);
        expect(await r.bookmarks(t), before);
        expect(await wirdState(t, r), state);
        // The sheet reads the state again when it opens.
        await r.longPressAyah(t, baqarah282, page: 48);
        expect(noteRowTexts(t), [kAyahNoteLabel, 'أراجع هنا']);
      },
    );

    testWidgets(
      'an empty save («$empty») on an ayah with no bookmark creates nothing and shows nothing',
      (t) async {
        final r = await pumpAyahBookmarkReader(t, startPage: 48);
        final state = await wirdState(t, r);
        await openNote(t, r);
        await saveNote(t, empty);
        expect(await r.bookmarks(t), isEmpty);
        expect(find.byType(SnackBar), findsNothing);
        expect(noteField, findsNothing);
        expect(ayahNoteRow, findsNothing, reason: 'the sheet closed');
        expect(highlighted(t), 0);
        expect(await wirdState(t, r), state);
      },
    );
  }

  testWidgets(
    'cancel writes nothing, shows nothing and leaves the sheet open',
    (t) async {
      final r = await pumpAyahBookmarkReader(
        t,
        startPage: 48,
        seed: (db, repo, meta, wirdId) async {
          await seedAyahBookmark(
            db,
            meta,
            baqarah282,
            wirdId: wirdId,
            note: 'أراجع هنا',
            at: seededAt,
          );
        },
      );
      final before = await r.bookmarks(t);
      await openNote(t, r);
      await t.enterText(noteField, 'لن تحفظ');
      await t.tap(byKey('ayah-note-cancel'));
      await settleReader(t);
      expect(noteField, findsNothing);
      expect(ayahNoteRow, findsOneWidget, reason: 'the sheet stays open');
      expect(find.byType(SnackBar), findsNothing);
      expect(await r.bookmarks(t), before);
      // The sheet still works: the same row opens the field again with the stored note.
      await t.tap(ayahNoteRow);
      await settleReader(t);
      expect(t.widget<TextField>(noteField).controller!.text, 'أراجع هنا');
    },
  );

  testWidgets(
    'removing a bookmark that has a note and «تراجع» bring the note back',
    (t) async {
      final r = await pumpAyahBookmarkReader(t, startPage: 48);
      await openNote(t, r);
      await saveNote(t, 'أراجع هنا');
      await t.pump(const Duration(seconds: 5)); // the message goes by itself
      final before = await r.bookmarks(t);
      expect(before.single.note, 'أراجع هنا');
      await r.longPressAyah(t, baqarah282, page: 48);
      await r.tapRow(t, ayahBookmarkRow);
      expect(await r.bookmarks(t), isEmpty);
      expect(message(kAyahBookmarkRemoved(surah, 282)), findsOneWidget);
      await undo(t);
      expect(await r.bookmarks(t), before);
    },
  );

  testWidgets(
    'the note shows in «علامات» as a page note does and survives a backup round trip',
    (t) async {
      late int pageId;
      final r = await pumpAyahBookmarkReader(
        t,
        startPage: 48,
        seed: (db, repo, meta, wirdId) async {
          pageId = await repo.addBookmark(77, 'ملاحظة صفحة', wirdId: wirdId);
        },
      );
      await openNote(t, r);
      await saveNote(t, 'أراجع هنا');
      await t.pump(const Duration(seconds: 5));
      final rows = await r.bookmarks(t);
      final ayah = rows.singleWhere((b) => b.surah != null);

      await openList(t);
      final ayahNote = find.descendant(
        of: byKey('bookmark-${ayah.id}'),
        matching: find.text('أراجع هنا'),
      );
      final pageNote = find.descendant(
        of: byKey('bookmark-$pageId'),
        matching: find.text('ملاحظة صفحة'),
      );
      expect(ayahNote, findsOneWidget);
      expect(pageNote, findsOneWidget);
      expect(t.widget<Text>(ayahNote).style, t.widget<Text>(pageNote).style);

      final restored = (await t.runAsync(() async {
        final file = await BackupService(r.db, meta: r.meta).exportJson();
        final other = AppDatabase(NativeDatabase.memory());
        try {
          await BackupService(other, meta: r.meta).importJson(file);
          return await allBookmarks(other);
        } finally {
          await other.close();
        }
      }))!;
      final back = restored.singleWhere((b) => b.surah != null);
      expect(
        (back.surah, back.ayah, back.page, back.note, back.wirdId),
        (2, 282, 48, 'أراجع هنا', ayah.wirdId),
      );
      expect(restored, hasLength(2));
    },
  );

  for (final mode in ['wird', 'browse']) {
    testWidgets(
      '$mode: a note saved for another scope is not shown and is not touched',
      (t) async {
        late List<Bookmark> foreign;
        final r = await pumpAyahBookmarkReader(
          t,
          startPage: 48,
          browseWithWird: mode == 'browse',
          seed: (db, repo, meta, wirdId) async {
            final other = await secondWird(repo);
            // Every scope that is not the reader's: the other wird, and the general ones in wird mode or the active
            // wird's in browse mode.
            for (final scope in [other, mode == 'browse' ? wirdId : null]) {
              await seedAyahBookmark(
                db,
                meta,
                baqarah282,
                wirdId: scope,
                note: 'لغير هذا',
                at: seededAt,
              );
            }
            foreign = await allBookmarks(db);
          },
        );
        expect(foreign, hasLength(2));
        await r.longPressAyah(t, baqarah282, page: 48);
        expect(noteRowTexts(t), [
          kAyahNoteLabel,
        ], reason: 'another scope\'s note is not this ayah\'s note here');
        await t.tap(ayahNoteRow);
        await settleReader(t);
        expect(t.widget<TextField>(noteField).controller!.text, '');
        expect(find.text(kAyahNoteHintNew), findsOneWidget);
        await saveNote(t, 'لهذا');
        expect(message(kAyahNoteCreated(surah, 282)), findsOneWidget);
        final rows = await r.bookmarks(t);
        expect(rows, hasLength(3));
        expect(rows.take(2), foreign, reason: 'the other scopes are untouched');
        final scope = mode == 'browse'
            ? null
            : (await t.runAsync(() => r.repo.activeWird()))!.id;
        expect((rows.last.note, rows.last.wirdId), ('لهذا', scope));
        await undo(t);
        expect(await r.bookmarks(t), foreign);
      },
    );
  }

  testWidgets(
    'a failing write keeps the field open with the typed text and shows no message in the reader',
    (t) async {
      final r = await pumpAyahBookmarkReader(
        t,
        startPage: 48,
        makeRepo: FailingNoteRepo.new,
      );
      await openNote(t, r);
      await saveNote(t, 'أراجع هنا');
      expect(find.text(kAyahNoteFailed), findsOneWidget);
      expect(t.widget<TextField>(noteField).controller!.text, 'أراجع هنا');
      expect(find.byType(SnackBar), findsNothing);
      expect(await r.bookmarks(t), isEmpty);
      await t.tap(byKey('ayah-note-cancel'));
      await settleReader(t);
      expect(ayahNoteRow, findsOneWidget, reason: 'the sheet is still open');
    },
  );
}
