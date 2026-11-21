// The six steps of the first-run tips (feature 008, data-model.md TipStep): fixed, ordered, short, free of Quran text.
import 'package:flutter_test/flutter_test.dart';
import 'package:mushaf/onboarding/tip_steps.dart';
import 'package:mushaf/onboarding/tips_strings.dart';

void main() {
  test('there are exactly six steps, in the order of the spec', () {
    expect(kTipSteps, hasLength(6));
    expect(kTipSteps.map((s) => s.picture).toList(), [
      TipPicture.longPress,
      TipPicture.turnPages,
      TipPicture.barsAndZoom,
      TipPicture.wird,
      TipPicture.bookmarks,
      TipPicture.sizeAndLook,
    ]);
  });

  test('every picture is used once', () {
    final used = kTipSteps.map((s) => s.picture).toSet();
    expect(used, hasLength(kTipSteps.length));
    expect(used, TipPicture.values.toSet());
  });

  test('titles and bodies come from the strings file', () {
    expect(kTipSteps.map((s) => s.title).toList(), [
      kTipLongPressTitle,
      kTipTurnPagesTitle,
      kTipBarsZoomTitle,
      kTipWirdTitle,
      kTipBookmarksTitle,
      kTipSizeLookTitle,
    ]);
    expect(kTipSteps.map((s) => s.body).toList(), [
      kTipLongPressBody,
      kTipTurnPagesBody,
      kTipBarsZoomBody,
      kTipWirdBody,
      kTipBookmarksBody,
      kTipSizeLookBody,
    ]);
  });

  final digits = RegExp(r'[0-9٠-٩۰-۹]');
  // Quranic annotation marks (U+06D6 to U+06ED) and the ornate brackets the Mushaf text is written between.
  final quranMarks = RegExp('[ۖ-ۭ﴾﴿]');

  for (var i = 0; i < kTipSteps.length; i++) {
    final step = kTipSteps[i];
    test('step ${i + 1} has a title and at most two sentences', () {
      expect(step.title.trim(), isNotEmpty);
      expect(step.title, isNot(matches(digits)));
      expect(step.body.trim(), isNotEmpty);
      expect('.'.allMatches(step.body).length, lessThanOrEqualTo(2));
      expect(step.body.trim(), endsWith('.'));
    });

    test('step ${i + 1} holds no Quran text', () {
      expect(step.title, isNot(matches(quranMarks)));
      expect(step.body, isNot(matches(quranMarks)));
    });
  }

  test('no title and no body is repeated', () {
    expect(kTipSteps.map((s) => s.title).toSet(), hasLength(6));
    expect(kTipSteps.map((s) => s.body).toSet(), hasLength(6));
  });
}
