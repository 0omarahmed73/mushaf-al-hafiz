// Leaving the khatm dua without «آمين» (spec User Story 2: FR-007, FR-008, FR-014; SC-002; contracts/ui.md table of actions).
// Back leaves the reader on page 604 with nothing written; a second forward swipe opens the dua again.
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mushaf/khatm/khatm_dua_screen.dart';

import '../support/khatm_harness.dart';
import '../support/reader_harness.dart';

Future<void> arrowBack(WidgetTester t) async {
  await t.tap(find.byType(BackButton));
  await settleReader(t);
}

Future<void> systemBack(WidgetTester t) async {
  await t.binding.handlePopRoute();
  await settleReader(t);
}

void main() {
  group('a reader following a wird', () {
    for (final (name, back) in [
      ('the back arrow', arrowBack),
      ('the system back', systemBack),
    ]) {
      testWidgets('$name leaves page 604 and writes nothing', (t) async {
        final reader = await pumpSizedReader(t, startPage: 604);
        await t.runAsync(() => reader.repo.addBookmark(604, 'علامة'));
        final before = await untouched(t, reader.repo);
        final lastBefore = await t.runAsync(() => reader.repo.lastViewedPage());
        await drag(t, 120);
        expect(duaOpen, isTrue);
        await back(t);
        expect(find.byType(KhatmDuaScreen), findsNothing);
        expect(pageNumber(t), '604');
        final wird = await t.runAsync(() => reader.repo.activeWird());
        expect(wird!.currentPage, 604, reason: 'the wird stays where it was');
        expect(
          await t.runAsync(() => reader.repo.lastViewedPage()),
          lastBefore,
          reason: 'the last viewed page is not written by back',
        );
        expect(await untouched(t, reader.repo), before);
      });
    }

    testWidgets(
      'a second forward swipe opens the dua again, and «آمين» then still shows page 1',
      (t) async {
        await pumpSizedReader(t, startPage: 604);
        await drag(t, 120);
        await arrowBack(t);
        expect(duaOpen, isFalse);
        await drag(t, 120);
        expect(duaOpen, isTrue);
        await tapAmen(t);
        expect(pageNumber(t), '1');
      },
    );
  });

  group('browse mode', () {
    for (final (name, back) in [
      ('the back arrow', arrowBack),
      ('the system back', systemBack),
    ]) {
      testWidgets('$name leaves page 604 and the last viewed page', (t) async {
        final repo = await pumpBrowseReader(t, startPage: 604);
        await drag(t, 120);
        expect(duaOpen, isTrue);
        await back(t);
        expect(pageNumber(t), '604');
        expect(await t.runAsync(() => repo.lastViewedPage()), 604);
        expect(await t.runAsync(() => repo.activeWird()), isNull);
      });
    }
  });

  group('the dua stays as it was', () {
    testWidgets(
      'a rotation (the window changes shape) keeps it open and back still leaves 604',
      (t) async {
        await pumpSizedReader(t, startPage: 604);
        await drag(t, 120);
        expect(duaOpen, isTrue);
        t.view.physicalSize = const Size(915, 412);
        await settleReader(t);
        expect(duaOpen, isTrue);
        expect(find.byType(KhatmDuaScreen), findsOneWidget);
        t.view.physicalSize = const Size(412, 915);
        await settleReader(t);
        expect(duaOpen, isTrue);
        await arrowBack(t);
        expect(pageNumber(t), '604');
      },
    );

    testWidgets('the app going to the background and back keeps it open', (
      t,
    ) async {
      await pumpSizedReader(t, startPage: 604);
      await drag(t, 120);
      t.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      t.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await t.pump(const Duration(seconds: 1));
      t.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      t.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await settleReader(t);
      expect(duaOpen, isTrue);
      expect(find.byType(KhatmDuaScreen), findsOneWidget);
    });
  });
}
