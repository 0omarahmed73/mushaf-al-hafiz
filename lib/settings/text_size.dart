/// The sizes the owner can choose for the reading texts and the Mushaf page, as a percentage of today's
/// look (spec FR-001, data-model.md TextSize).
abstract final class TextSize {
  /// The eight stops of the slider, in percent.
  static const List<int> steps = [80, 90, 100, 110, 120, 130, 140, 150];

  /// Today's look.
  static const int defaultPercent = 100;

  /// The multiplier for [percent].
  static double factor(int percent) => percent / 100;

  /// The step a stored value means. Never throws (spec FR-014): a missing value, something that is not a
  /// whole number, or a number outside the range is [defaultPercent]; a number inside the range that is not a
  /// step is the nearest step, with a tie going to the lower one.
  static int parse(String? raw) {
    final value = int.tryParse(raw?.trim() ?? '');
    if (value == null || value < steps.first || value > steps.last) {
      return defaultPercent;
    }
    var best = steps.first;
    for (final step in steps) {
      if ((step - value).abs() < (best - value).abs()) best = step;
    }
    return best;
  }
}
