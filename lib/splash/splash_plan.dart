/// The time rules of the splash (spec FR-009 to FR-011). Pure: no Flutter import, so the rules are unit-tested alone.
abstract final class SplashPlan {
  /// The whole choreography; after it the last frame stays.
  static const Duration fullDuration = Duration(milliseconds: 1400);

  /// The least time the splash stays with full motion. Everything but the thin line has settled by then (research D3).
  static const Duration minimum = Duration(milliseconds: 900);

  /// The least time the splash stays when the phone asks for reduced motion.
  static const Duration reducedStay = Duration(milliseconds: 300);

  /// The fade out. Reduced motion has none.
  static const Duration fade = Duration(milliseconds: 220);

  /// Whether the splash may start leaving. [elapsed] is the time since its first frame. A tap ([skipped]) removes the
  /// minimum, but never the wait for [ready]: leaving earlier would show an unfinished app.
  static bool mayLeave({
    required Duration elapsed,
    required bool ready,
    required bool skipped,
    required bool reducedMotion,
  }) {
    if (!ready) return false;
    if (skipped) return true;
    return elapsed >= (reducedMotion ? reducedStay : minimum);
  }
}
