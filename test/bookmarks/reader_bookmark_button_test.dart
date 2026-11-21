// The bookmark icon in the reader (feature 006, task T009): where it sits, what one tap adds, how the icon follows the
// page and the sheet, and everything a tap must leave alone (spec FR-001 to FR-005, FR-008, SC-001, SC-002, SC-006).
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mushaf/look/look_choice.dart';
import 'package:mushaf/wirds/wird_repository.dart';

import '../support/bookmark_harness.dart';
import '../support/reader_harness.dart' show settleReader;

Finder get button => key('bookmark-button');

Finder get filled =>
    find.descendant(of: button, matching: find.byIcon(Icons.bookmark_added));

Finder get outlined => find.descendant(
  of: button,
  matching: find.byIcon(Icons.bookmark_add_outlined),
);

/// What a tap on the icon must not change.
Future<List<Object?>> stable(WidgetTester t, WirdRepository repo) async {
  return (await t.runAsync(() async {
    final wird = await repo.activeWird();
    final today = await repo.watchTodayEntries().first;
    return <Object?>[
      wird == null
          ? null
          : (
              wird.id,
              wird.currentPage,
              wird.khatmaCount,
              wird.notifyEnabled,
              wird.notifyMinutes,
            ),
      [
        for (final e in today)
          (e.wird.id, e.day.startPage, e.day.endPage, e.done),
      ],
      await repo.lastViewedPage(),
      await repo.textSizeRaw(),
      await repo.appLookRaw(),
      await repo.kahfEnabled(),
      await repo.kahfMinutes(),
    ];
  }))!;
}

Future<List<Bookmark>> bookmarks(WidgetTester t, WirdRepository repo) async =>
    (await t.runAsync(
      () async => [
        for (final e in await repo.watchBookmarks().first) e.bookmark,
      ],
    ))!;

Future<void> tapIcon(WidgetTester t) async {
  await t.tap(button);
  await settleReader(t);
}

Future<void> flingNext(WidgetTester t) async {
  await t.fling(find.byType(PageView), const Offset(400, 0), 1500);
  await settleReader(t);
}

Future<void> flingPrevious(WidgetTester t) async {
  await t.fling(find.byType(PageView), const Offset(-400, 0), 1500);
  await settleReader(t);
}

void main() {
  group('place', () {
    for (final screen in const [Size(412, 915), Size(320, 640)]) {
      testWidgets(
        '${screen.width.toInt()} dp: far left, directly under the juz text',
        (t) async {
          await pumpBookmarkReader(t, screen: screen);
          expect(button, findsOneWidget);
          final icon = t.getRect(button);
          final juz = t.getRect(key('juz-hizb'));
          expect(
            icon.left,
            lessThanOrEqualTo(12),
            reason: 'the far left of the screen',
          );
          expect(
            icon.top,
            greaterThanOrEqualTo(juz.bottom),
            reason: 'under the juz text',
          );
          expect(
            icon.left < juz.right && icon.right > juz.left,
            isTrue,
            reason: 'in the same column as the juz text',
          );
          expect(
            icon.bottom,
            lessThanOrEqualTo(t.getRect(key('top-bar')).bottom),
            reason: 'inside the 84 px bar',
          );
          expect(icon.width, greaterThanOrEqualTo(48));
          expect(icon.height, greaterThanOrEqualTo(48));
        },
      );
    }

    testWidgets(
      'in browse mode «اجعلها موضعي» is shown too and they do not touch',
      (t) async {
        await pumpBookmarkReader(t, browseWithWird: true);
        expect(find.text('اجعلها موضعي'), findsOneWidget);
        final icon = t.getRect(button);
        final make = t.getRect(find.text('اجعلها موضعي'));
        expect(icon.overlaps(make), isFalse);
        expect(
          make.right,
          lessThanOrEqualTo(icon.left > 0 ? 412.0 : 0),
          reason: 'a sanity bound, both on screen',
        );
        await t.tap(find.text('اجعلها موضعي'));
        await settleReader(t);
        expect(
          find.text('اجعلها موضعي'),
          findsNothing,
          reason: 'the text button still works beside the icon',
        );
      },
    );
  });

  group('one tap adds', () {
    testWidgets(
      'following a wird: one bookmark of that wird, no note, the icon fills, nothing else moves',
      (t) async {
        final reader = await pumpBookmarkReader(t, startPage: 50);
        expect(outlined, findsOneWidget);
        expect(filled, findsNothing);
        final before = await stable(t, reader.repo);
        final wirdId = (await t.runAsync(() => reader.repo.activeWird()))!.id;
        await tapIcon(t);
        final all = await bookmarks(t, reader.repo);
        expect(all, hasLength(1));
        expect(all.single.page, 50);
        expect(all.single.wirdId, wirdId);
        expect(all.single.note, isNull);
        expect(filled, findsOneWidget);
        expect(outlined, findsNothing);
        expect(shownPage(t), '50', reason: 'the page did not turn');
        expect(await stable(t, reader.repo), before);
      },
    );

    testWidgets('browsing with no wird: the bookmark is general', (t) async {
      final reader = await pumpBookmarkReader(t, startPage: 50, noWird: true);
      final before = await stable(t, reader.repo);
      await tapIcon(t);
      final all = await bookmarks(t, reader.repo);
      expect(all, hasLength(1));
      expect(all.single.wirdId, isNull);
      expect(all.single.page, 50);
      expect(filled, findsOneWidget);
      expect(await stable(t, reader.repo), before);
    });

    testWidgets(
      'browsing with a wird (after a jump): general, and the wird stays where it was',
      (t) async {
        final reader = await pumpBookmarkReader(
          t,
          startPage: 50,
          browseWithWird: true,
        );
        expect(shownPage(t), '51');
        final before = await stable(t, reader.repo);
        await tapIcon(t);
        final all = await bookmarks(t, reader.repo);
        expect(all, hasLength(1));
        expect(all.single.wirdId, isNull);
        expect(all.single.page, 51);
        expect(await stable(t, reader.repo), before);
      },
    );

    testWidgets('the same in Night Reader', (t) async {
      final reader = await pumpBookmarkReader(t, look: LookChoice.night);
      await tapIcon(t);
      expect(await bookmarks(t, reader.repo), hasLength(1));
      expect(filled, findsOneWidget);
    });

    testWidgets('bookmarks of other pages are left alone', (t) async {
      final reader = await pumpBookmarkReader(t, startPage: 50);
      await t.runAsync(() => reader.repo.addBookmark(49, 'قبل'));
      await settleReader(t);
      await t.runAsync(() => reader.repo.addBookmark(51, 'بعد'));
      await settleReader(t);
      await tapIcon(t);
      expect(
        {for (final b in await bookmarks(t, reader.repo)) b.page},
        {49, 50, 51},
      );
    });
  });

  group('the icon follows', () {
    testWidgets('the page: a swipe to the next page and back', (t) async {
      await pumpBookmarkReader(t, startPage: 50);
      await tapIcon(t);
      expect(filled, findsOneWidget);
      await flingNext(t);
      expect(shownPage(t), '51');
      expect(outlined, findsOneWidget, reason: 'page 51 has no bookmark');
      await flingPrevious(t);
      expect(shownPage(t), '50');
      expect(filled, findsOneWidget);
    });

    testWidgets(
      'the sheet: a bookmark added there fills the icon, one swiped away there empties it',
      (t) async {
        final reader = await pumpBookmarkReader(t, startPage: 50);
        Future<void> openSheet() async {
          await t.tap(
            find.descendant(
              of: key('bottom-bar'),
              matching: find.text('علامات'),
            ),
          );
          await settleReader(t);
        }

        Future<void> closeSheet() async {
          await t.tapAt(const Offset(206, 20)); // the barrier closes the sheet
          await settleReader(t);
          expect(find.byKey(const ValueKey('bookmark-add')), findsNothing);
        }

        await openSheet();
        await t.tap(key('bookmark-add'));
        await settleReader(t);
        await t.tap(key('bookmark-save'));
        await settleReader(t);
        await closeSheet();
        expect(filled, findsOneWidget);
        expect(await bookmarks(t, reader.repo), hasLength(1));

        await openSheet();
        await t.drag(find.text('ص 50'), const Offset(-700, 0));
        await settleReader(t);
        await closeSheet();
        expect(await bookmarks(t, reader.repo), isEmpty);
        expect(outlined, findsOneWidget);
      },
    );

    testWidgets(
      'only the scope counts: another wird\'s bookmark on the page leaves it outlined',
      (t) async {
        final reader = await pumpBookmarkReader(t, startPage: 50);
        // One write per runAsync, with a pump in between: the reader's wird stream re-queries after the first write
        // inside the fake-async zone and holds the connection, so a second write in the same runAsync could wait for
        // a pump that never comes.
        final other = (await t.runAsync(
          () => reader.repo.create(
            const WirdDraft(
              name: 'آخر',
              type: WirdType.reading,
              startPage: 1,
              dailyPages: 5,
              color: 0xFF1565C0,
            ),
          ),
        ))!;
        await settleReader(t);
        await t.runAsync(
          () => reader.repo.addBookmark(50, 'لآخر', wirdId: other),
        );
        await settleReader(t);
        expect(outlined, findsOneWidget);
        expect(filled, findsNothing);
      },
    );

    testWidgets('a page that is already bookmarked opens filled', (t) async {
      await pumpBookmarkReader(
        t,
        startPage: 50,
        seed: (repo, wirdId) => repo.addBookmark(51, null, wirdId: wirdId),
      );
      expect(outlined, findsOneWidget, reason: 'page 50 has none');
      await flingNext(t);
      expect(shownPage(t), '51');
      expect(filled, findsOneWidget);
    });
  });
}
