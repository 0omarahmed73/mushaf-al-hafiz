// TipsGate (feature 008, spec User Story 1, FR-001, FR-002, FR-006, FR-007): the tips open once, after the first frame,
// and never again once they were finished, skipped or left by back.
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mushaf/onboarding/tips_dialog.dart';
import 'package:mushaf/onboarding/tips_store.dart';
import 'package:mushaf/wirds/db.dart';
import 'package:mushaf/wirds/wird_repository.dart';

import '../support/tips_harness.dart';

/// A repository whose read fails, as a damaged database would.
class _ReadFails extends WirdRepository {
  _ReadFails(super.db);

  @override
  Future<String?> readSetting(String key) =>
      Future.error(StateError('cannot read'));
}

/// A repository whose write fails (disk full).
class _WriteFails extends WirdRepository {
  _WriteFails(super.db);

  @override
  Future<void> writeSetting(String key, String value) =>
      Future.error(StateError('disk full'));
}

Future<String?> stored(WidgetTester t, WirdRepository repo) =>
    t.runAsync(() => repo.readSetting(kTipsSeenKey)).then((v) => v);

void main() {
  group('the first launch', () {
    testWidgets(
      'the child is shown at once and the popup opens after the first frame, not before',
      (t) async {
        tipsPhoneScreen(t);
        final repo = await openTipsRepository(t);
        await t.pumpWidget(tipsGateApp(repo));
        expect(key(kReaderPlaceholder), findsOneWidget);
        expect(
          find.byType(TipsDialog),
          findsNothing,
          reason: 'not before the first frame has been drawn',
        );
        await settleGate(t);
        expect(find.byType(TipsDialog), findsOneWidget);
        expect(
          key(kReaderPlaceholder),
          findsOneWidget,
          reason: 'the reader stays under the popup',
        );
        expect(currentStep(t), 0);
      },
    );

    testWidgets('it opens within one second of the first frame', (t) async {
      tipsPhoneScreen(t);
      final repo = await openTipsRepository(t);
      await t.pumpWidget(tipsGateApp(repo));
      // Fake time: ten frames of 90 ms is under one second.
      for (var i = 0; i < 10; i++) {
        await t.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)),
        );
        await t.pump(const Duration(milliseconds: 90));
      }
      expect(find.byType(TipsDialog), findsOneWidget);
    });

    testWidgets('it does not open when the tips were seen', (t) async {
      tipsPhoneScreen(t);
      final repo = await openTipsRepository(t);
      await t.runAsync(() => repo.writeSetting(kTipsSeenKey, 'true'));
      await t.pumpWidget(tipsGateApp(repo));
      await settleGate(t);
      expect(find.byType(TipsDialog), findsNothing);
      expect(key(kReaderPlaceholder), findsOneWidget);
    });

    for (final damaged in ['false', '', 'maybe', 'True']) {
      testWidgets('a stored value of "$damaged" is not seen: it opens', (
        t,
      ) async {
        tipsPhoneScreen(t);
        final repo = await openTipsRepository(t);
        await t.runAsync(() => repo.writeSetting(kTipsSeenKey, damaged));
        await t.pumpWidget(tipsGateApp(repo));
        await settleGate(t);
        expect(find.byType(TipsDialog), findsOneWidget);
      });
    }
  });

  group('how the tips end, and what is stored', () {
    testWidgets('finishing stores the flag and the popup is gone', (t) async {
      tipsPhoneScreen(t);
      final repo = await openTipsRepository(t);
      await t.pumpWidget(tipsGateApp(repo));
      await settleGate(t);
      await finishTips(t);
      expect(find.byType(TipsDialog), findsNothing);
      expect(await stored(t, repo), 'true');
      expect(key(kReaderPlaceholder), findsOneWidget);
    });

    testWidgets('«تخطي» on step 1 stores the flag', (t) async {
      tipsPhoneScreen(t);
      final repo = await openTipsRepository(t);
      await t.pumpWidget(tipsGateApp(repo));
      await settleGate(t);
      await t.tap(skipButton);
      await settleGate(t, rounds: 4);
      expect(find.byType(TipsDialog), findsNothing);
      expect(await stored(t, repo), 'true');
    });

    testWidgets('the system back on step 3 stores the flag', (t) async {
      tipsPhoneScreen(t);
      final repo = await openTipsRepository(t);
      await t.pumpWidget(tipsGateApp(repo));
      await settleGate(t);
      await tapNext(t);
      await tapNext(t);
      await systemBack(t);
      await settleGate(t, rounds: 4);
      expect(find.byType(TipsDialog), findsNothing);
      expect(await stored(t, repo), 'true');
    });

    testWidgets('a touch outside stores nothing and the popup stays', (
      t,
    ) async {
      tipsPhoneScreen(t);
      final repo = await openTipsRepository(t);
      await t.pumpWidget(tipsGateApp(repo));
      await settleGate(t);
      await t.tapAt(const Offset(4, 4));
      await settleGate(t, rounds: 3);
      expect(find.byType(TipsDialog), findsOneWidget);
      expect(await stored(t, repo), isNull);
    });

    testWidgets(
      'a close without a result (a navigation that pops everything) stores nothing, and the tips come back next start',
      (t) async {
        tipsPhoneScreen(t);
        final repo = await openTipsRepository(t);
        await t.pumpWidget(tipsGateApp(repo));
        await settleGate(t);
        Navigator.of(t.element(key('tips-pages')))
            .popUntil((route) => route.isFirst);
        await settleGate(t, rounds: 4);
        expect(find.byType(TipsDialog), findsNothing);
        expect(await stored(t, repo), isNull);
        // The next start.
        await t.pumpWidget(const SizedBox());
        await t.pumpWidget(tipsGateApp(repo));
        await settleGate(t);
        expect(find.byType(TipsDialog), findsOneWidget);
      },
    );

    testWidgets('the flag is the only thing it writes', (t) async {
      tipsPhoneScreen(t);
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(() async {
        await t.pumpWidget(const SizedBox());
        await t.pump(const Duration(seconds: 1));
        await t.runAsync(db.close);
      });
      await t.pumpWidget(tipsGateApp(WirdRepository(db)));
      await settleGate(t);
      await t.tap(skipButton);
      await settleGate(t, rounds: 4);
      final rows = await t.runAsync(() => db.select(db.settings).get());
      expect(rows!.map((r) => r.key).toList(), [kTipsSeenKey]);
    });
  });

  group('never again', () {
    testWidgets(
      'the same data in a rebuilt app shows nothing, after finish, after skip and after back',
      (t) async {
        for (final how in ['finish', 'skip', 'back']) {
          await t.pumpWidget(const SizedBox());
          tipsPhoneScreen(t);
          final repo = await openTipsRepository(t);
          await t.pumpWidget(tipsGateApp(repo));
          await settleGate(t);
          expect(find.byType(TipsDialog), findsOneWidget, reason: how);
          switch (how) {
            case 'finish':
              await finishTips(t);
            case 'skip':
              await t.tap(skipButton);
              await settleGate(t, rounds: 4);
            default:
              await systemBack(t);
              await settleGate(t, rounds: 4);
          }
          expect(find.byType(TipsDialog), findsNothing, reason: how);
          // Unmount everything and build the app again on the same repository.
          await t.pumpWidget(const SizedBox());
          await t.pumpWidget(tipsGateApp(repo));
          await settleGate(t);
          expect(
            find.byType(TipsDialog),
            findsNothing,
            reason: 'rebuilt after $how',
          );
          expect(key(kReaderPlaceholder), findsOneWidget);
        }
      },
    );

    testWidgets(
      'the same screen rebuilt (a look change, a new parent) does not open it twice',
      (t) async {
        tipsPhoneScreen(t);
        final repo = await openTipsRepository(t);
        await t.pumpWidget(tipsGateApp(repo));
        await settleGate(t);
        await t.pumpWidget(tipsGateApp(repo));
        await settleGate(t);
        expect(find.byType(TipsDialog), findsOneWidget);
      },
    );

    testWidgets('a real restart: the flag goes through a file database', (
      t,
    ) async {
      tipsPhoneScreen(t);
      final dir = Directory.systemTemp.createTempSync('tips_restart');
      addTearDown(() => dir.deleteSync(recursive: true));
      final file = File('${dir.path}/mushaf.sqlite');

      Future<AppDatabase> open() async => AppDatabase(NativeDatabase(file));

      // First start: the tips open and are skipped.
      var db = await open();
      await t.pumpWidget(tipsGateApp(WirdRepository(db)));
      await settleGate(t);
      expect(find.byType(TipsDialog), findsOneWidget);
      await t.tap(skipButton);
      await settleGate(t, rounds: 4);
      await t.pumpWidget(const SizedBox());
      await t.pump(const Duration(seconds: 1));
      await t.runAsync(db.close);

      // Second start: a new connection to the same file, a new repository, a new app.
      db = await open();
      await t.pumpWidget(tipsGateApp(WirdRepository(db)));
      await settleGate(t);
      expect(find.byType(TipsDialog), findsNothing);
      expect(
        await t.runAsync(() => WirdRepository(db).readSetting(kTipsSeenKey)),
        'true',
      );
      await t.pumpWidget(const SizedBox());
      await t.pump(const Duration(seconds: 1));
      await t.runAsync(db.close);
    });

    testWidgets('a restart before the tips were finished shows them again', (
      t,
    ) async {
      tipsPhoneScreen(t);
      final dir = Directory.systemTemp.createTempSync('tips_unfinished');
      addTearDown(() => dir.deleteSync(recursive: true));
      final file = File('${dir.path}/mushaf.sqlite');

      var db = AppDatabase(NativeDatabase(file));
      await t.pumpWidget(tipsGateApp(WirdRepository(db)));
      await settleGate(t);
      expect(find.byType(TipsDialog), findsOneWidget);
      await tapNext(t);
      // The app is killed here: nothing was finished or skipped.
      await t.pumpWidget(const SizedBox());
      await t.pump(const Duration(seconds: 1));
      await t.runAsync(db.close);

      db = AppDatabase(NativeDatabase(file));
      await t.pumpWidget(tipsGateApp(WirdRepository(db)));
      await settleGate(t);
      expect(find.byType(TipsDialog), findsOneWidget);
      expect(currentStep(t), 0, reason: 'it starts again from step 1');
      await t.pumpWidget(const SizedBox());
      await t.pump(const Duration(seconds: 1));
      await t.runAsync(db.close);
    });
  });

  group('waiting for the splash', () {
    testWidgets(
      'enabled: false shows nothing, and turning it on opens the popup once',
      (t) async {
        tipsPhoneScreen(t);
        final repo = await openTipsRepository(t);
        await t.pumpWidget(tipsGateApp(repo, enabled: false));
        await settleGate(t);
        expect(find.byType(TipsDialog), findsNothing);
        expect(key(kReaderPlaceholder), findsOneWidget);

        await t.pumpWidget(tipsGateApp(repo));
        await settleGate(t);
        expect(find.byType(TipsDialog), findsOneWidget);

        // Turning it off and on again does not open a second one.
        await t.pumpWidget(tipsGateApp(repo, enabled: false));
        await t.pumpWidget(tipsGateApp(repo));
        await settleGate(t);
        expect(find.byType(TipsDialog), findsOneWidget);
      },
    );
  });

  group('failures never block the reader', () {
    testWidgets('a read that fails shows no popup and no error', (t) async {
      tipsPhoneScreen(t);
      final repo = await openTipsRepository(t, make: _ReadFails.new);
      await t.pumpWidget(tipsGateApp(repo));
      await settleGate(t);
      expect(find.byType(TipsDialog), findsNothing);
      expect(key(kReaderPlaceholder), findsOneWidget);
      expect(t.takeException(), isNull);
    });

    testWidgets('a write that fails still closes the popup, with no error', (
      t,
    ) async {
      tipsPhoneScreen(t);
      final repo = await openTipsRepository(t, make: _WriteFails.new);
      await t.pumpWidget(tipsGateApp(repo));
      await settleGate(t);
      await t.tap(skipButton);
      await settleGate(t, rounds: 4);
      expect(find.byType(TipsDialog), findsNothing);
      expect(t.takeException(), isNull);
    });

    testWidgets(
      'without a repository in the tree the child is shown and nothing opens',
      (t) async {
        tipsPhoneScreen(t);
        await t.pumpWidget(
          const MaterialApp(
            home: Text('plain', key: ValueKey(kReaderPlaceholder)),
          ),
        );
        expect(key(kReaderPlaceholder), findsOneWidget);
        expect(find.byType(TipsDialog), findsNothing);
      },
    );
  });

  group('no stream is held', () {
    testWidgets(
      'the database can be written with runAsync while the gate is mounted, and nothing hangs',
      (t) async {
        tipsPhoneScreen(t);
        final repo = await openTipsRepository(t);
        await t.runAsync(() => repo.writeSetting(kTipsSeenKey, 'true'));
        await t.pumpWidget(tipsGateApp(repo));
        await settleGate(t);
        await t.runAsync(() async {
          await repo.ensureDefaults();
          await repo.addBookmark(12, 'note');
          await repo.writeSetting('textSizePercent', '110');
        });
        await settleGate(t, rounds: 3);
        expect(find.byType(TipsDialog), findsNothing);
        expect(t.takeException(), isNull);
      },
    );
  });
}
