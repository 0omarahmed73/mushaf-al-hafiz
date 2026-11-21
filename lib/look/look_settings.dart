import 'package:flutter/foundation.dart';

import '../mushaf/page_look.dart';
import '../theme.dart';
import '../wirds/wird_repository.dart';
import 'look_choice.dart';

/// The look the owner chose (spec FR-001, FR-003, FR-016). It lives in the settings table, so the backup carries
/// it; the app listens to it and changes at once, without a restart.
class AppLookSettings extends ChangeNotifier {
  AppLookSettings(this._repo);

  final WirdRepository _repo;
  LookChoice _choice = LookChoice.defaultChoice;

  /// The chosen look; Emerald and Gold until one is chosen.
  LookChoice get choice => _choice;

  /// The colours and shapes of the chosen look.
  AppLook get look => _choice.look;

  /// How a Mushaf page is drawn in the chosen look (the reader, the picture and the PDF).
  PageLook get pageLook => _choice.pageLook;

  /// Reads the stored look (Emerald when nothing, or something unusable, is stored). Never writes.
  Future<void> load() async {
    _apply(LookChoice.parse(await _repo.appLookRaw()));
  }

  /// Reads it again after something changed the stored value behind our back (a restored backup).
  Future<void> reload() => load();

  /// Chooses [next]: saved at once; listeners hear only a real change.
  Future<void> set(LookChoice next) async {
    final changed = _apply(next);
    if (changed || await _repo.appLookRaw() != next.name) {
      await _repo.setAppLook(next.name);
    }
  }

  bool _apply(LookChoice next) {
    if (next == _choice) return false;
    _choice = next;
    notifyListeners();
    return true;
  }
}
