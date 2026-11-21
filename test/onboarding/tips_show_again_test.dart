// showTips (feature 008, spec User Story 3, FR-009): the tips can be opened again by any screen, whatever the stored
// state, and never twice at once.
import 'dart:async' show unawaited;

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mushaf/app.dart';
import 'package:mushaf/mushaf/mushaf_repository.dart';
import 'package:mushaf/onboarding/tips_dialog.dart';
import 'package:mushaf/onboarding/tips_gate.dart';
import 'package:mushaf/onboarding/tips_store.dart';
import 'package:mushaf/wirds/wird_repository.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../support/tips_harness.dart';

class _WriteFails extends WirdRepository {
  _WriteFails(super.db);

  @override
  Future<void> writeSetting(String key, String value) =>
      Future.error(StateError('disk full'));
}

/// What a screen with a «show the tips again» row would see.
class _Launcher {
  BuildContext? context;
  int calls = 0;
  int finished = 0;

  Widget get screen => Scaffold(
    body: Builder(
      builder: (c) {
        context = c;
        return Center(
          child: TextButton(
            key: const ValueKey('show-tips'),
            onPressed: call,
            child: const Text('tips'),
          ),
        );
      },
    ),
  );

  Future<void> call() {
    calls++;
    return showTips(context!).then((_) => finished++);
  }
}

Future<String?> stored(WidgetTester t, WirdRepository repo) async =>
    await t.runAsync<String?>(() => repo.readSetting(kTipsSeenKey));

void main() {
  group('with the app around it', () {
    testWidgets(
      'with the tips already seen it opens at step 1 and returns only when they close',
      (t) async {
        tipsPhoneScreen(t);
        final repo = await openTipsRepository(t);
        await t.runAsync(() => repo.writeSetting(kTipsSeenKey, 'true'));
        final launcher = _Launcher();
        await t.pumpWidget(tipsGateApp(repo, child: launcher.screen));
        await settleGate(t);
        expect(find.byType(TipsDialog), findsNothing);

        await t.tap(key('show-tips'));
        await settleGate(t);
        expect(find.byType(TipsDialog), findsOneWidget);
        expect(currentStep(t), 0);
        expect(
          launcher.finished,
          0,
          reason: 'it has not returned while the dialog is open',
        );
        await tapNext(t);

        await t.tap(skipButton);
        await settleGate(t, rounds: 4);
        expect(find.byType(TipsDialog), findsNothing);
        expect(launcher.finished, 1);
      },
    );

    testWidgets('finishing them again leaves them seen', (t) async {
      tipsPhoneScreen(t);
      final repo = await openTipsRepository(t);
      await t.runAsync(() => repo.writeSetting(kTipsSeenKey, 'true'));
      final launcher = _Launcher();
      await t.pumpWidget(tipsGateApp(repo, child: launcher.screen));
      await settleGate(t);
      await t.tap(key('show-tips'));
      await settleGate(t);
      await finishTips(t);
      expect(launcher.finished, 1);
      expect(await stored(t, repo), 'true');
    });

    testWidgets('with the flag absent, skipping them stores it', (t) async {
      tipsPhoneScreen(t);
      final repo = await openTipsRepository(t);
      // The gate would open them by itself, so the screen is shown without one.
      final launcher = _Launcher();
      await t.pumpWidget(
        MushafApp(
          wirdRepository: repo,
          mushafRepository: MushafRepository(rootBundle),
          home: launcher.screen,
        ),
      );
      await settleGate(t);
      expect(await stored(t, repo), isNull);
      await t.tap(key('show-tips'));
      await settleGate(t);
      await t.tap(skipButton);
      await settleGate(t, rounds: 4);
      expect(await stored(t, repo), 'true');
    });

    testWidgets(
      'a second call while one is open does nothing, and after it closes a call opens another',
      (t) async {
        tipsPhoneScreen(t);
        final repo = await openTipsRepository(t);
        await t.runAsync(() => repo.writeSetting(kTipsSeenKey, 'true'));
        final launcher = _Launcher();
        await t.pumpWidget(tipsGateApp(repo, child: launcher.screen));
        await settleGate(t);

        unawaited(launcher.call());
        unawaited(launcher.call());
        unawaited(launcher.call());
        await settleGate(t);
        expect(find.byType(TipsDialog), findsOneWidget);
        expect(
          launcher.finished,
          2,
          reason: 'the two extra calls returned at once',
        );

        await t.tap(skipButton);
        await settleGate(t, rounds: 4);
        expect(find.byType(TipsDialog), findsNothing);
        expect(launcher.finished, 3);

        unawaited(launcher.call());
        await settleGate(t);
        expect(
          find.byType(TipsDialog),
          findsOneWidget,
          reason: 'one can be opened again',
        );
      },
    );

    testWidgets(
      'a gate built again while the popup is open does not open a second one',
      (t) async {
        tipsPhoneScreen(t);
        final repo = await openTipsRepository(t);
        await t.pumpWidget(tipsGateApp(repo, gateKey: const ValueKey('one')));
        await settleGate(t);
        expect(find.byType(TipsDialog), findsOneWidget);
        // The app is rebuilt around the open popup: a new gate asks the database, which still says "not seen".
        await t.pumpWidget(tipsGateApp(repo, gateKey: const ValueKey('two')));
        await settleGate(t);
        expect(find.byType(TipsDialog), findsOneWidget);
        await t.tap(skipButton);
        await settleGate(t, rounds: 4);
        expect(
          find.byType(TipsDialog),
          findsNothing,
          reason: 'there was only one to close',
        );
      },
    );

    testWidgets('it never throws when the repository does', (t) async {
      tipsPhoneScreen(t);
      final repo = await openTipsRepository(t, make: _WriteFails.new);
      final launcher = _Launcher();
      await t.pumpWidget(
        MushafApp(
          wirdRepository: repo,
          mushafRepository: MushafRepository(rootBundle),
          home: launcher.screen,
        ),
      );
      await settleGate(t);
      await t.tap(key('show-tips'));
      await settleGate(t);
      await t.tap(skipButton);
      await settleGate(t, rounds: 4);
      expect(launcher.finished, 1);
      expect(t.takeException(), isNull);
    });
  });

  group('without a repository in the tree', () {
    testWidgets('the tips still show and close, and nothing is stored', (
      t,
    ) async {
      tipsPhoneScreen(t);
      final launcher = _Launcher();
      await t.pumpWidget(MaterialApp(home: launcher.screen));
      await t.tap(key('show-tips'));
      await settleTips(t);
      expect(find.byType(TipsDialog), findsOneWidget);
      await t.tap(skipButton);
      await settleTips(t);
      expect(find.byType(TipsDialog), findsNothing);
      expect(launcher.finished, 1);
      expect(t.takeException(), isNull);
    });
  });
}
