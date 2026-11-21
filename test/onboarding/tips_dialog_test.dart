// The first-run tips card (feature 008, spec User Story 1): dots, «التالي», «تخطي», «ابدأ», back, and the swipe in the
// right-to-left direction of the paper Mushaf.
import 'package:flutter/semantics.dart' show SemanticsNode;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mushaf/onboarding/tip_steps.dart';
import 'package:mushaf/onboarding/tips_dialog.dart';
import 'package:mushaf/onboarding/tips_strings.dart';

import '../support/tips_harness.dart';

/// A finger from left to right on the card: the paper-Mushaf direction, forward.
Future<void> swipeForward(WidgetTester t) async {
  await t.fling(key('tips-pages'), const Offset(300, 0), 1200);
  await settleTips(t);
}

Future<void> swipeBack(WidgetTester t) async {
  await t.fling(key('tips-pages'), const Offset(-300, 0), 1200);
  await settleTips(t);
}

void main() {
  group('the first step', () {
    testWidgets(
      'opens on step 1 of 6 with its title, the dots and the two buttons',
      (t) async {
        await pumpTipsDialog(t);
        expect(find.byType(TipsDialog), findsOneWidget);
        expect(find.text(kTipLongPressTitle), findsOneWidget);
        expect(find.text(kTipLongPressBody), findsOneWidget);
        expect(dotWidths(t), hasLength(6));
        expect(currentStep(t), 0);
        expect(nextButton, findsOneWidget);
        expect(skipButton, findsOneWidget);
        expect(startButton, findsNothing);
        expect(find.text(kTipsNext), findsOneWidget);
        expect(find.text(kTipsSkip), findsOneWidget);
      },
    );

    testWidgets(
      '«تخطي» sits at the start (right) and «التالي» at the end (left)',
      (t) async {
        await pumpTipsDialog(t);
        final card = t.getCenter(key('tips-dialog')).dx;
        expect(t.getCenter(skipButton).dx, greaterThan(card));
        expect(t.getCenter(nextButton).dx, lessThan(card));
      },
    );
  });

  group('«التالي» and the dots', () {
    testWidgets(
      'goes through the six steps, the dots follow, and the last shows «ابدأ» only',
      (t) async {
        await pumpTipsDialog(t);
        for (var i = 1; i < kTipSteps.length; i++) {
          await tapNext(t);
          expect(currentStep(t), i);
          expect(
            find.byKey(ValueKey('tips-step-title-$i')).hitTestable(),
            findsOneWidget,
          );
        }
        expect(startButton, findsOneWidget);
        expect(nextButton, findsNothing);
        expect(skipButton, findsNothing);
        expect(find.text(kTipsStart), findsOneWidget);
        // At the end (left), where «التالي» was.
        expect(
          t.getCenter(startButton).dx,
          lessThan(t.getCenter(key('tips-dialog')).dx),
        );
      },
    );

    testWidgets('exactly one dot is current at any moment', (t) async {
      await pumpTipsDialog(t);
      for (var i = 0; i < kTipSteps.length; i++) {
        final widths = dotWidths(t);
        final widest = widths.reduce((a, b) => a > b ? a : b);
        expect(
          widths.where((w) => w == widest),
          hasLength(1),
          reason: 'step ${i + 1}',
        );
        expect(
          widths.where((w) => w < widest).toSet(),
          hasLength(1),
          reason: 'the others are all alike',
        );
        if (i < kTipSteps.length - 1) await tapNext(t);
      }
    });

    testWidgets('two quick taps on «التالي» move one step, not two', (t) async {
      await pumpTipsDialog(t);
      await t.tap(nextButton);
      await t.tap(nextButton);
      await settleTips(t);
      expect(currentStep(t), 1);
    });

    testWidgets('two quick taps near the end never skip the last step', (
      t,
    ) async {
      await pumpTipsDialog(t);
      for (var i = 0; i < 4; i++) {
        await tapNext(t);
      }
      expect(currentStep(t), 4);
      await t.tap(nextButton);
      await t.tap(nextButton);
      await settleTips(t);
      expect(currentStep(t), 5);
      expect(startButton, findsOneWidget);
    });
  });

  group('the swipe, in the direction of the paper Mushaf', () {
    testWidgets(
      'dragging a finger to the right brings the next step in from the left',
      (t) async {
        await pumpTipsDialog(t);
        final gesture = await t.startGesture(t.getCenter(key('tips-pages')));
        await gesture.moveBy(const Offset(120, 0));
        await t.pump();
        final here = t.getCenter(key('tips-step-title-0')).dx;
        final next = t.getCenter(key('tips-step-title-1')).dx;
        expect(next, lessThan(here), reason: 'step 2 waits on the left');
        // The step that was shown follows the finger to the right.
        expect(here, greaterThan(t.getCenter(key('tips-dialog')).dx));
        await gesture.up();
        await settleTips(t);
      },
    );

    testWidgets('a swipe from left to right moves forward on every step', (
      t,
    ) async {
      await pumpTipsDialog(t);
      for (var i = 1; i < kTipSteps.length; i++) {
        await swipeForward(t);
        expect(currentStep(t), i);
        expect(key('tips-step-title-$i').hitTestable(), findsOneWidget);
      }
    });

    testWidgets('a swipe from right to left goes back one step', (t) async {
      await pumpTipsDialog(t);
      await tapNext(t);
      await tapNext(t);
      expect(currentStep(t), 2);
      await swipeBack(t);
      expect(currentStep(t), 1);
    });

    testWidgets('a swipe beyond step 1 does nothing', (t) async {
      await pumpTipsDialog(t);
      await swipeBack(t);
      expect(currentStep(t), 0);
      expect(find.byType(TipsDialog), findsOneWidget);
    });

    testWidgets(
      'a swipe beyond step 6 does nothing and does not close the card',
      (t) async {
        final probe = await pumpTipsDialog(t);
        for (var i = 1; i < kTipSteps.length; i++) {
          await swipeForward(t);
        }
        expect(currentStep(t), 5);
        await swipeForward(t);
        expect(currentStep(t), 5);
        expect(find.byType(TipsDialog), findsOneWidget);
        expect(probe.closed, isFalse);
      },
    );

    testWidgets(
      'it is right-to-left by itself, also in an app with no Arabic locale',
      (t) async {
        await pumpTipsDialog(t, arabic: false);
        expect(
          Directionality.of(t.element(key('tips-pages'))),
          TextDirection.rtl,
        );
        await swipeForward(t);
        expect(currentStep(t), 1);
        final card = t.getCenter(key('tips-dialog')).dx;
        expect(t.getCenter(nextButton).dx, lessThan(card));
        expect(t.getCenter(skipButton).dx, greaterThan(card));
      },
    );
  });

  group('closing', () {
    testWidgets('«ابدأ» closes with finished', (t) async {
      final probe = await pumpTipsDialog(t);
      for (var i = 1; i < kTipSteps.length; i++) {
        await tapNext(t);
      }
      expect(probe.closed, isFalse, reason: '«التالي» never closes it');
      await t.tap(startButton);
      await settleTips(t);
      expect(probe.closed, isTrue);
      expect(probe.outcome, TipsOutcome.finished);
      expect(find.byType(TipsDialog), findsNothing);
    });

    testWidgets('«تخطي» closes with skipped, from any step', (t) async {
      for (final steps in [0, 3]) {
        final probe = await pumpTipsDialog(t);
        for (var i = 0; i < steps; i++) {
          await tapNext(t);
        }
        await t.tap(skipButton);
        await settleTips(t);
        expect(probe.closed, isTrue, reason: 'after $steps «التالي»');
        expect(probe.outcome, TipsOutcome.skipped);
        expect(find.byType(TipsDialog), findsNothing);
      }
    });

    testWidgets('the system back closes with skipped, from any step', (
      t,
    ) async {
      final probe = await pumpTipsDialog(t);
      await tapNext(t);
      await tapNext(t);
      await systemBack(t);
      expect(probe.closed, isTrue);
      expect(probe.outcome, TipsOutcome.skipped);
      expect(find.byType(TipsDialog), findsNothing);
    });

    testWidgets('a touch on the dimmed area outside does nothing', (t) async {
      final probe = await pumpTipsDialog(t);
      await t.tapAt(const Offset(4, 4));
      await settleTips(t);
      expect(find.byType(TipsDialog), findsOneWidget);
      expect(probe.closed, isFalse);
      expect(currentStep(t), 0);
    });

    testWidgets('closing the route without a result leaves the outcome null', (
      t,
    ) async {
      final probe = await pumpTipsDialog(t);
      Navigator.of(t.element(key('tips-pages'))).pop();
      await settleTips(t);
      expect(probe.closed, isTrue);
      expect(probe.outcome, isNull);
    });
  });

  group('what a screen reader hears', () {
    /// Every label in the semantics tree, in order.
    List<String> allLabels(WidgetTester t) {
      final labels = <String>[];
      void visit(SemanticsNode node) {
        if (node.label.isNotEmpty) labels.add(node.label);
        node.visitChildren((child) {
          visit(child);
          return true;
        });
      }

      visit(
        t.binding.renderViews.first.owner!.semanticsOwner!.rootSemanticsNode!,
      );
      return labels;
    }

    testWidgets('the dialog is named and scopes its route', (t) async {
      final handle = t.ensureSemantics();
      await pumpTipsDialog(t);
      expect(
        t.getSemantics(key('tips-semantics')),
        isSemantics(
          label: kTipsDialogLabel,
          namesRoute: true,
          scopesRoute: true,
        ),
      );
      handle.dispose();
    });

    testWidgets(
      'each step is announced as one live line, «الخطوة N من 6», and the dots add nothing else',
      (t) async {
        final handle = t.ensureSemantics();
        await pumpTipsDialog(t);
        for (var i = 0; i < kTipSteps.length; i++) {
          expect(
            t.getSemantics(key('tips-step-semantics')),
            isSemantics(label: kTipsStepOf(i + 1, 6), isLiveRegion: true),
            reason: 'step ${i + 1}',
          );
          final announcements = allLabels(t).where((l) => l.contains('الخطوة'));
          expect(announcements, [
            kTipsStepOf(i + 1, 6),
          ], reason: 'one node, not one per dot');
          if (i < kTipSteps.length - 1) await tapNext(t);
        }
        handle.dispose();
      },
    );

    testWidgets('each title is a heading', (t) async {
      final handle = t.ensureSemantics();
      await pumpTipsDialog(t);
      for (var i = 0; i < kTipSteps.length; i++) {
        expect(
          t.getSemantics(key('tips-step-title-$i')),
          isSemantics(label: kTipSteps[i].title, isHeader: true),
          reason: 'step ${i + 1}',
        );
        if (i < kTipSteps.length - 1) await tapNext(t);
      }
      handle.dispose();
    });

    testWidgets(
      'the buttons are buttons with their names, and the picture says nothing',
      (t) async {
        final handle = t.ensureSemantics();
        await pumpTipsDialog(t);
        expect(
          t.getSemantics(skipButton),
          isSemantics(isButton: true, label: kTipsSkip),
        );
        expect(
          t.getSemantics(nextButton),
          isSemantics(isButton: true, label: kTipsNext),
        );
        final labels = allLabels(t).join('\n');
        for (final heard in [
          kTipsDialogLabel,
          kTipLongPressTitle,
          kTipLongPressBody,
          kTipsSkip,
          kTipsNext,
        ]) {
          expect(labels, contains(heard));
        }
        // Nothing is read for the drawing: no label of the tree is an icon's private-use character.
        expect(RegExp('[\uE000-\uF8FF]').hasMatch(labels), isFalse);
        for (var i = 0; i < kTipSteps.length - 1; i++) {
          await tapNext(t);
        }
        expect(
          t.getSemantics(startButton),
          isSemantics(isButton: true, label: kTipsStart),
        );
        handle.dispose();
      },
    );

    testWidgets('after «التالي» the announcement changes', (t) async {
      final handle = t.ensureSemantics();
      await pumpTipsDialog(t);
      expect(allLabels(t), contains(kTipsStepOf(1, 6)));
      await tapNext(t);
      final labels = allLabels(t);
      expect(labels, contains(kTipsStepOf(2, 6)));
      expect(labels, isNot(contains(kTipsStepOf(1, 6))));
      handle.dispose();
    });
  });
}
