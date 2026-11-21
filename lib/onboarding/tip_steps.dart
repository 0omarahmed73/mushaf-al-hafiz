import 'tips_strings.dart';

/// The drawing of a step (`tip_picture.dart` draws them).
enum TipPicture {
  longPress,
  turnPages,
  barsAndZoom,
  wird,
  bookmarks,
  sizeAndLook,
}

/// One step of the first-run tips: a drawing, a title and at most two sentences (data-model.md `TipStep`). Plain data, no
/// widget: the six steps are fixed and never stored.
class TipStep {
  const TipStep({
    required this.picture,
    required this.title,
    required this.body,
  });

  final TipPicture picture;
  final String title;
  final String body;
}

/// The six steps, in the order they are shown. Every one describes something the app really does
/// (test/onboarding/tips_reader_truth_test.dart does each of them on the real reader).
const List<TipStep> kTipSteps = [
  TipStep(
    picture: TipPicture.longPress,
    title: kTipLongPressTitle,
    body: kTipLongPressBody,
  ),
  TipStep(
    picture: TipPicture.turnPages,
    title: kTipTurnPagesTitle,
    body: kTipTurnPagesBody,
  ),
  TipStep(
    picture: TipPicture.barsAndZoom,
    title: kTipBarsZoomTitle,
    body: kTipBarsZoomBody,
  ),
  TipStep(picture: TipPicture.wird, title: kTipWirdTitle, body: kTipWirdBody),
  TipStep(
    picture: TipPicture.bookmarks,
    title: kTipBookmarksTitle,
    body: kTipBookmarksBody,
  ),
  TipStep(
    picture: TipPicture.sizeAndLook,
    title: kTipSizeLookTitle,
    body: kTipSizeLookBody,
  ),
];
