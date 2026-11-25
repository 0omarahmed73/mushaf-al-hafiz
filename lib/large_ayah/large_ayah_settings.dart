import 'package:flutter/foundation.dart';

import '../ayah/ayah_ref.dart';
import '../mushaf/models.dart';
import '../wirds/wird_repository.dart';

/// The large-ayah view's settings (feature 015, data-model.md "Stored: settings keys", research D8): whether it is on, the
/// ayat per screen, the size step and the first ayah of the last screen shown. They live in the settings table, so the
/// backup carries them; parsing never throws and a value that is not usable is the default.
class LargeAyahSettings extends ChangeNotifier {
  LargeAyahSettings(this._repo, {MushafMeta? meta})
    : _meta = meta; // ignore: prefer_initializing_formals, a named parameter cannot be private

  final WirdRepository _repo;
  final MushafMeta? _meta;

  /// The font-size factor of size steps 1, 2 and 3 (research D2).
  static const List<double> factors = [2.0, 2.5, 3.0];

  bool _on = false;
  int _count = 1;
  int _sizeStep = 1;
  AyahRef? _at;

  /// True while the view replaces the Mushaf pager; when on, the app opens on it (constitution 2.2.0, Principle II).
  bool get on => _on;

  /// Ayat per screen, 1..3.
  int get count => _count;

  /// Size step, 1..3.
  int get sizeStep => _sizeStep;

  double get factor => factors[_sizeStep - 1];

  /// The first ayah of the last screen shown, or null.
  AyahRef? get at => _at;

  static int _step(String? raw) => switch (raw) {
    '2' => 2,
    '3' => 3,
    _ => 1,
  };

  AyahRef? _parseAt(String? raw) {
    final parts = (raw ?? '').split(':');
    if (parts.length != 2) return null;
    final surah = int.tryParse(parts[0]);
    final ayah = int.tryParse(parts[1]);
    if (surah == null || ayah == null || surah < 1 || surah > MushafMeta.surahCount || ayah < 1) return null;
    final meta = _meta;
    if (meta != null) {
      if (surah > meta.surahs.length || ayah > meta.surah(surah).ayahs) return null;
    }
    return AyahRef(surah, ayah);
  }

  /// Reads the stored values. Never writes.
  Future<void> load() async {
    final on = await _repo.largeAyahRaw() == 'true';
    final count = _step(await _repo.largeAyahCountRaw());
    final size = _step(await _repo.largeAyahSizeRaw());
    _at = _parseAt(await _repo.largeAyahAtRaw());
    if (on != _on || count != _count || size != _sizeStep) {
      _on = on;
      _count = count;
      _sizeStep = size;
      notifyListeners();
    }
  }

  /// Reads them again after a restored backup.
  Future<void> reload() => load();

  Future<void> setOn(bool on) async {
    await _repo.setLargeAyah(on);
    if (on == _on) return;
    _on = on;
    notifyListeners();
  }

  Future<void> setCount(int count) async {
    _checkStep(count, 'count');
    await _repo.setLargeAyahCount(count);
    if (count == _count) return;
    _count = count;
    notifyListeners();
  }

  Future<void> setSizeStep(int step) async {
    _checkStep(step, 'step');
    await _repo.setLargeAyahSize(step);
    if (step == _sizeStep) return;
    _sizeStep = step;
    notifyListeners();
  }

  /// Remembers [ref] without notifying: it changes on every screen and nothing redraws for it.
  Future<void> setAt(AyahRef ref) async {
    if (ref == _at) return;
    _at = ref;
    await _repo.setLargeAyahAt(ref.key);
  }

  static void _checkStep(int value, String name) {
    if (value < 1 || value > 3) throw ArgumentError.value(value, name, 'must be 1, 2 or 3');
  }
}
