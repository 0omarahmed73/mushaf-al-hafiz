import 'package:material_ui/material_ui.dart';

/// The durations, curves and distances of the soft motion of feature 010 (specs/010-smooth-motion/contracts/ui.md), in
/// one place, and the rule that the phone's «remove animations» setting switches all of it off.
///
/// Motion is modest: a fade and a slide of at most [barSlide] dp, 160 to 220 ms, easing out when something appears and
/// easing in when it leaves; no bounce, no loop. Nothing here moves or resizes the Mushaf page.
abstract final class Motion {
  /// The top and bottom bars appearing and leaving.
  static const Duration barIn = Duration(milliseconds: 200);
  static const Duration barOut = Duration(milliseconds: 160);

  /// The «ملخص اليوم» card opening and closing.
  static const Duration cardIn = Duration(milliseconds: 220);
  static const Duration cardOut = Duration(milliseconds: 160);

  /// A page arriving after a jump (index, go-to-page, bookmark, notification, another wird).
  static const Duration jump = Duration(milliseconds: 180);

  /// The bookmark icon and the wird name changing.
  static const Duration swap = Duration(milliseconds: 160);

  /// The look cross-fade.
  static const Duration look = Duration(milliseconds: 220);

  /// The edge turn of a page wider than the screen (unchanged from feature 003).
  static const Duration edgeTurn = Duration(milliseconds: 300);

  /// Curves: easing out when something appears, easing in when it leaves.
  static const Curve enter = Curves.easeOutCubic;
  static const Curve exit = Curves.easeInCubic;

  /// Slide distances in dp.
  static const double barSlide = 24;
  static const double cardSlide = 12;

  /// True while the phone's «remove animations» setting is on.
  static bool reduced(BuildContext context) =>
      MediaQuery.disableAnimationsOf(context);

  /// [d], or [Duration.zero] when [reduced]. Read when a motion starts, so a change of the setting applies to the next one.
  static Duration of(BuildContext context, Duration d) =>
      reduced(context) ? Duration.zero : d;
}
