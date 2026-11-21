import 'package:flutter/foundation.dart';

import '../wirds/wird_repository.dart';
import 'text_size.dart';

/// The size the owner chose for the reading texts and the Mushaf page (spec FR-001..FR-004). It lives in the
/// settings table, so the backup carries it; screens listen to it and change at once, without a restart.
class TextSizeSettings extends ChangeNotifier {
  TextSizeSettings(this._repo);

  final WirdRepository _repo;
  int _percent = TextSize.defaultPercent;

  /// The chosen step, 80..150; 100 is today's look.
  int get percent => _percent;

  double get factor => TextSize.factor(_percent);

  bool get isDefault => _percent == TextSize.defaultPercent;

  /// Reads the stored size (the default when nothing, or something unusable, is stored). Never writes.
  Future<void> load() async {
    _apply(TextSize.parse(await _repo.textSizeRaw()));
  }

  /// Reads it again after something changed the stored value behind our back (a restored backup).
  Future<void> reload() => load();

  /// Chooses [percent]: a size that is not a step snaps to the nearest one and one outside the range is the
  /// default (the same rule as for a stored value). Saved at once; listeners hear only a real change.
  Future<void> set(int percent) async {
    final next = TextSize.parse('$percent');
    final changed = _apply(next);
    if (changed || await _repo.textSizeRaw() != '$next') {
      await _repo.setTextSizePercent(next);
    }
  }

  /// Back to today's look.
  Future<void> reset() => set(TextSize.defaultPercent);

  bool _apply(int percent) {
    if (percent == _percent) return false;
    _percent = percent;
    notifyListeners();
    return true;
  }
}
