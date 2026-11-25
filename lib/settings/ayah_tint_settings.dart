import 'package:flutter/foundation.dart';

import '../wirds/wird_repository.dart';

/// The Settings switch «تظليل الآيات التي عليها علامة» (feature 013, spec FR-024; research D7): whether the Mushaf page draws
/// the light tint behind the ayat that have an ayah bookmark of the current scope. It lives in the settings table under
/// `ayahTint` (`'true'` / `'false'`), so the backup carries it; absent or any other text is on. The reader listens to it
/// and changes at once, without a restart.
class AyahTintSettings extends ChangeNotifier {
  AyahTintSettings(this._repo);

  final WirdRepository _repo;
  bool _enabled = true;

  /// True until a stored 'false'.
  bool get enabled => _enabled;

  static bool _parse(String? raw) => raw != 'false';

  /// Reads the stored switch (on when nothing, or something unusable, is stored). Never writes.
  Future<void> load() async {
    _apply(_parse(await _repo.ayahTintRaw()));
  }

  /// Reads it again after something changed the stored value behind our back (a restored backup).
  Future<void> reload() => load();

  /// Saved at once; listeners hear only a real change.
  Future<void> set(bool enabled) async {
    final changed = _apply(enabled);
    if (changed || await _repo.ayahTintRaw() != '$enabled') {
      await _repo.setAyahTint(enabled);
    }
  }

  bool _apply(bool enabled) {
    if (enabled == _enabled) return false;
    _enabled = enabled;
    notifyListeners();
    return true;
  }
}
