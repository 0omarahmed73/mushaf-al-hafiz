// End to end through the reader (feature 013, task T020; spec FR-003 to FR-007, FR-019, SC-001, SC-008, SC-009): long press a
// word, tap the sheet's bookmark row, and the bookmark is made on the page where the ayah begins, owned by the scope, with a
// message and «تراجع»; the next time the row removes it; nothing else of the wird moves.
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mushaf/ayah/ayah_ref.dart';
import 'package:mushaf/mushaf/ayah_bookmark_strings.dart';
import 'package:mushaf/mushaf/bookmark_strings.dart';
import 'package:mushaf/mushaf/page_look.dart';
import 'package:mushaf/wirds/ayah_bookmark_change.dart';
import 'package:mushaf/wirds/wird_repository.dart';

import '../support/ayah_bookmark_harness.dart';
import '../support/reader_harness.dart' show settleReader;

const baqarah282 = AyahRef(2, 282);

/// Everything an ayah bookmark action must leave as it was: the wirds (position, khatma count), today's portions and the
/// settings (last viewed page and the rest).
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

String rowLabel(WidgetTester t) {
  final texts = t.widgetList<Text>(
    find.descendant(of: ayahBookmarkRow, matching: find.byType(Text)),
  );
  return texts.first.data!;
}

class FailingAyahRepo extends WirdRepository {
  FailingAyahRepo(super.db);

  @override
  Future<AyahBookmarkChange> toggleAyahBookmark(
    AyahRef ref, {
    required int page,
    int? wirdId,
  }) async => throw StateError('disk full');
}

void main() {
  testWidgets(
    'wird mode: one tap adds one ayah bookmark of the wird on the page where it begins, with the message',
    (t) async {
      final r = await pumpAyahBookmarkReader(t, startPage: 48);
      final before = await wirdState(t, r);
      await r.longPressAyah(t, baqarah282, page: 48);
      expect(highlighted(t), greaterThan(0));
      expect(rowLabel(t), kAyahBookmarkAddLabel);
      await r.tapRow(t, ayahBookmarkRow);

      final marks = await r.bookmarks(t);
      expect(marks, hasLength(1));
      final b = marks.single;
      final wird = (await t.runAsync(() => r.repo.activeWird()))!;
      expect(
        (b.surah, b.ayah, b.page, b.note, b.wirdId),
        (2, 282, 48, null, wird.id),
      );
      expect(ayahBookmarkRow, findsNothing, reason: 'the sheet closed');
      expect(highlighted(t), 0, reason: 'the ayah\'s highlight ended');
      final added = message(kAyahBookmarkAdded('البقرة', 282));
      expect(added, findsOneWidget);
      expect(find.text(kBookmarkUndo), findsOneWidget);
      final bar = t.getRect(byKey('bottom-bar'));
      // The message's text and its action are above the bottom bar (the SnackBar's own box spans its margin).
      for (final part in [added, find.text(kBookmarkUndo)]) {
        expect(
          t.getRect(part).bottom,
          lessThanOrEqualTo(bar.top + 0.01),
          reason: 'above the bottom bar',
        );
      }
      expect(await wirdState(t, r), before);

      await t.tap(find.text(kBookmarkUndo));
      await settleReader(t);
      expect(await r.bookmarks(t), isEmpty, reason: '«تراجع» removed it');
      expect(await wirdState(t, r), before);
    },
  );

  testWidgets(
    'the row then says «remove»; a tap removes it, «تراجع» brings it back with its note and time',
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
            at: DateTime(2026, 11, 1, 8),
          );
        },
      );
      final before = await r.bookmarks(t);
      final state = await wirdState(t, r);
      await r.longPressAyah(t, baqarah282, page: 48);
      expect(rowLabel(t), kAyahBookmarkRemoveLabel);
      await r.tapRow(t, ayahBookmarkRow);
      expect(await r.bookmarks(t), isEmpty);
      expect(message(kAyahBookmarkRemoved('البقرة', 282)), findsOneWidget);
      await t.tap(find.text(kBookmarkUndo));
      await settleReader(t);
      expect(await r.bookmarks(t), before);
      expect(await wirdState(t, r), state);
      // The sheet reads the state again when it opens.
      await r.longPressAyah(t, baqarah282, page: 48);
      expect(rowLabel(t), kAyahBookmarkRemoveLabel);
    },
  );

  testWidgets('add, then the next long press reads «remove»', (t) async {
    final r = await pumpAyahBookmarkReader(t, startPage: 48);
    await r.longPressAyah(t, baqarah282, page: 48);
    await r.tapRow(t, ayahBookmarkRow);
    await t.pump(const Duration(seconds: 5)); // the message goes by itself
    await r.longPressAyah(t, baqarah282, page: 48);
    expect(rowLabel(t), kAyahBookmarkRemoveLabel);
  });

  for (final mode in ['browse with a wird', 'no wird']) {
    testWidgets(
      '$mode: the bookmark is general and the position does not move',
      (t) async {
        final r = await pumpAyahBookmarkReader(
          t,
          startPage: 48,
          browseWithWird: mode == 'browse with a wird',
          noWird: mode == 'no wird',
        );
        expect(shownPage(t), '48');
        final before = await wirdState(t, r);
        await r.longPressAyah(t, baqarah282, page: 48);
        await r.tapRow(t, ayahBookmarkRow);
        final b = (await r.bookmarks(t)).single;
        expect((b.surah, b.ayah, b.page, b.wirdId), (2, 282, 48, null));
        expect(await wirdState(t, r), before);
      },
    );
  }

  testWidgets('a bookmark of another wird is neither shown nor touched', (
    t,
  ) async {
    late Bookmark other;
    final r = await pumpAyahBookmarkReader(
      t,
      startPage: 48,
      seed: (db, repo, meta, wirdId) async {
        final w2 = await repo.create(
          const WirdDraft(
            name: 'الثاني',
            type: WirdType.reading,
            dailyPages: 5,
            color: 0xFF1565C0,
          ),
        );
        await seedAyahBookmark(
          db,
          meta,
          baqarah282,
          wirdId: w2,
          note: 'للثاني',
        );
        other = (await db.select(db.bookmarks).get()).single;
      },
    );
    await r.longPressAyah(t, baqarah282, page: 48);
    expect(
      rowLabel(t),
      kAyahBookmarkAddLabel,
      reason: 'the other wird\'s bookmark is not this scope\'s state',
    );
    await r.tapRow(t, ayahBookmarkRow);
    await t.pump(const Duration(seconds: 5));
    await r.longPressAyah(t, baqarah282, page: 48);
    await r.tapRow(t, ayahBookmarkRow);
    expect(await r.bookmarks(t), [other]);
  });

  testWidgets(
    'a quick double tap leaves the ayah bookmarked once or not at all',
    (t) async {
      final r = await pumpAyahBookmarkReader(t, startPage: 48);
      await r.longPressAyah(t, baqarah282, page: 48);
      await t.tap(ayahBookmarkRow);
      await t.tap(ayahBookmarkRow, warnIfMissed: false);
      await settleReader(t);
      expect((await r.bookmarks(t)).length, lessThanOrEqualTo(1));
    },
  );

  testWidgets('a failing write shows no «added» message', (t) async {
    final r = await pumpAyahBookmarkReader(
      t,
      startPage: 48,
      makeRepo: FailingAyahRepo.new,
    );
    await r.longPressAyah(t, baqarah282, page: 48);
    await r.tapRow(t, ayahBookmarkRow);
    expect(await r.bookmarks(t), isEmpty);
    expect(find.byType(SnackBar), findsNothing);
    expect(highlighted(t), 0);
  });
}
