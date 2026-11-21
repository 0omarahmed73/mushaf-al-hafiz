// The message after a tap on the reader's bookmark icon and its «تراجع» (feature 006, tasks T011/T012; spec FR-007,
// FR-009, SC-009; research D4): one floating SnackBar above the bottom bar, replaced by the next tap, and an undo that
// puts back exactly what that tap changed.
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mushaf/mushaf/bookmark_strings.dart';
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
Finder get undo => find.widgetWithText(SnackBarAction, kBookmarkUndo);

Future<List<Bookmark>> rows(WidgetTester t, WirdRepository repo) async =>
    (await t.runAsync(
      () async => [
        for (final e in await repo.watchBookmarks().first) e.bookmark,
      ],
    ))!;

Future<void> tapIcon(WidgetTester t) async {
  await t.tap(button);
  await settleReader(t);
}

/// Fails every toggle, like a full disk would.
class _FailingRepository extends WirdRepository {
  _FailingRepository(super.db);

  @override
  Future<BookmarkToggle> toggleBookmark(int page, {int? wirdId}) =>
      Future.error(StateError('disk full'));
}

void main() {
  testWidgets('an add shows the message with «تراجع», above the bottom bar', (
    t,
  ) async {
    await pumpBookmarkReader(t, startPage: 50);
    expect(find.byType(SnackBar), findsNothing);
    await tapIcon(t);
    expect(find.text(kBookmarkAdded(50)), findsOneWidget);
    expect(undo, findsOneWidget);
    final bar = t.getRect(key('bottom-bar'));
    final text = t.getRect(find.text(kBookmarkAdded(50)));
    final action = t.getRect(undo);
    expect(
      text.bottom,
      lessThanOrEqualTo(bar.top),
      reason: 'the message never covers the bottom bar',
    );
    expect(
      action.bottom,
      lessThanOrEqualTo(bar.top),
      reason: 'the message never covers the bottom bar',
    );
  });

  testWidgets('a removal shows its own message', (t) async {
    final reader = await pumpBookmarkReader(t, startPage: 50);
    await tapIcon(t);
    await tapIcon(t);
    expect(find.text(kBookmarkRemoved(50)), findsOneWidget);
    expect(find.text(kBookmarkAdded(50)), findsNothing);
    expect(await rows(t, reader.repo), isEmpty);
    expect(outlined, findsOneWidget);
  });

  testWidgets('a new tap replaces the message, there is one at a time', (
    t,
  ) async {
    await pumpBookmarkReader(t, startPage: 50);
    await tapIcon(t);
    await tapIcon(t);
    await tapIcon(t);
    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.text(kBookmarkAdded(50)), findsOneWidget);
  });

  testWidgets('«تراجع» after an add removes that bookmark', (t) async {
    final reader = await pumpBookmarkReader(t, startPage: 50);
    await tapIcon(t);
    expect(filled, findsOneWidget);
    await t.tap(undo);
    await settleReader(t);
    expect(await rows(t, reader.repo), isEmpty);
    expect(outlined, findsOneWidget);
  });

  testWidgets(
    '«تراجع» after a removal brings the very same bookmark back (id, note, time)',
    (t) async {
      final reader = await pumpBookmarkReader(t, startPage: 50);
      final wirdId = (await t.runAsync(() => reader.repo.activeWird()))!.id;
      for (final (page, note) in [
        (50, 'ملاحظة أولى'),
        (50, 'ملاحظة ثانية'),
        (51, 'صفحة أخرى'),
      ]) {
        await t.runAsync(
          () => reader.repo.addBookmark(page, note, wirdId: wirdId),
        );
        await settleReader(t);
      }
      final before = await rows(t, reader.repo);
      // The reader reads the table again when the «علامات» sheet closes: open it and close it.
      await t.tap(
        find.descendant(of: key('bottom-bar'), matching: find.text('علامات')),
      );
      await settleReader(t);
      await t.tapAt(const Offset(206, 20));
      await settleReader(t);
      expect(filled, findsOneWidget);
      await tapIcon(t);
      expect(
        {for (final b in await rows(t, reader.repo)) b.page},
        {51},
        reason: 'both bookmarks of page 50 are gone',
      );
      await t.tap(undo);
      await settleReader(t);
      final after = await rows(t, reader.repo);
      expect(
        [for (final b in after) (b.id, b.page, b.wirdId, b.note, b.createdAt)],
        unorderedEquals([
          for (final b in before) (b.id, b.page, b.wirdId, b.note, b.createdAt),
        ]),
      );
      expect(filled, findsOneWidget);
    },
  );

  testWidgets('the message goes away by itself and «تراجع» goes with it', (
    t,
  ) async {
    await pumpBookmarkReader(t, startPage: 50);
    await tapIcon(t);
    expect(undo, findsOneWidget);
    await t.pump(const Duration(seconds: 6));
    await t.pump(const Duration(seconds: 1));
    expect(find.byType(SnackBar), findsNothing);
    expect(undo, findsNothing);
  });

  testWidgets('the message is the same in Night Reader and at 320 dp', (
    t,
  ) async {
    final reader = await pumpBookmarkReader(
      t,
      startPage: 50,
      screen: const Size(320, 640),
    );
    await tapIcon(t);
    expect(find.text(kBookmarkAdded(50)), findsOneWidget);
    expect(
      reader.unexpectedErrors,
      isEmpty,
      reason: 'the message must not overflow, only the bottom bar may (T020)',
    );
  });

  testWidgets('a failed write shows no message and leaves the icon as it was', (
    t,
  ) async {
    await pumpBookmarkReader(
      t,
      startPage: 50,
      makeRepo: _FailingRepository.new,
    );
    await tapIcon(t);
    expect(find.byType(SnackBar), findsNothing);
    expect(outlined, findsOneWidget);
  });
}
