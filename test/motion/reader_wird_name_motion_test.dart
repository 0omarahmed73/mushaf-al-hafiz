// Feature 010 T034 (FR-011): the wird name in the pill fades in when another wird is chosen, one name at a time.
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mushaf/motion/fade_in_on_change.dart';

import '../support/motion_harness.dart';

const _pill = ValueKey('wird-pill');

Finder get _nameTexts =>
    find.descendant(of: find.byKey(_pill), matching: find.byType(Text));

double _opacity(WidgetTester t) => t
    .widget<FadeTransition>(
      find
          .descendant(
            of: find.byKey(_pill),
            matching: find.byType(FadeTransition),
          )
          .first,
    )
    .opacity
    .value;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  tearDown(
    () => TestWidgetsFlutterBinding.instance.platformDispatcher
        .clearAccessibilityFeaturesTestValue(),
  );

  Future<void> chooseOtherWird(WidgetTester t) async {
    await t.tap(find.text('أوراد').last);
    await settleMotion(t, rounds: 6);
    // The wirds screen shows the name twice (the today card above and the list below); the list row opens the wird.
    await t.tap(find.text('ورد الاختبار').last);
  }

  testWidgets('the first build shows the name as it is', (t) async {
    await pumpMotionReader(t, startPage: 50, withWird: true, secondWird: true);
    expect(
      find.descendant(
        of: find.byKey(_pill),
        matching: find.byType(FadeInOnChange),
      ),
      findsOneWidget,
    );
    expect(_opacity(t), 1);
    expect(_nameTexts, findsOneWidget);
  });

  testWidgets(
    'choosing another wird shows the new name at once at opacity 0, 1.0 after 160 ms, one name at a time',
    (t) async {
      await pumpMotionReader(
        t,
        startPage: 50,
        withWird: true,
        secondWird: true,
      );
      final before = t.widget<Text>(_nameTexts).data;
      await chooseOtherWird(t);
      var seenNew = false;
      for (var i = 0; i < 80 && !seenNew; i++) {
        await t.pump(const Duration(milliseconds: 16));
        final texts = _nameTexts.evaluate().toList();
        expect(texts.length, 1, reason: 'one name in the pill at any time');
        if ((texts.single.widget as Text).data == 'ورد الاختبار') {
          seenNew = true;
          expect(
            _opacity(t),
            lessThan(0.3),
            reason: 'first frame of the new name',
          );
        }
      }
      expect(seenNew, isTrue);
      expect(before, isNot('ورد الاختبار'));
      await t.pump(const Duration(milliseconds: 80));
      expect(_opacity(t), allOf(greaterThan(0), lessThan(1)));
      await t.pump(const Duration(milliseconds: 100));
      expect(_opacity(t), 1);
      expect(_nameTexts, findsOneWidget);
    },
  );

  testWidgets(
    'with «remove animations» on the new name is complete in its first frame',
    (t) async {
      t.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      await pumpMotionReader(
        t,
        startPage: 50,
        withWird: true,
        secondWird: true,
      );
      await chooseOtherWird(t);
      for (var i = 0; i < 80; i++) {
        await t.pump(const Duration(milliseconds: 16));
        final texts = _nameTexts.evaluate().toList();
        if (texts.isNotEmpty &&
            (texts.single.widget as Text).data == 'ورد الاختبار') {
          expect(_opacity(t), 1);
          return;
        }
      }
      fail('the new name never appeared');
    },
  );
}
