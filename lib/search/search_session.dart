/// The logic of the search screen (feature 011, research D5 and D13; contracts/ui.md "States"; spec FR-009, FR-014, FR-023,
/// FR-027): what the field holds, the two groups of results, the answers of the service that are still current, and the
/// announcement a screen reader gets once the results have settled. No widget here.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../mushaf/models.dart';
import 'arabic_fold.dart';
import 'search_service.dart';
import 'search_strings.dart';
import 'surah_search.dart';

/// What the ayah group shows (contracts/ui.md "States").
sealed class AyahGroup {
  const AyahGroup();
}

/// Nothing typed (or no Arabic letter): the one line that says what can be typed.
class AyahHint extends AyahGroup {
  const AyahHint();
}

/// One letter: the line that asks for a second letter.
class AyahNeedsTwo extends AyahGroup {
  const AyahNeedsTwo();
}

/// Two or more letters and the text is not ready yet: the preparing line.
class AyahPreparing extends AyahGroup {
  const AyahPreparing();
}

/// Two or more letters and the preparation failed: the failure line and its button.
class AyahFailed extends AyahGroup {
  const AyahFailed(this.error);
  final Object error;
}

/// Two or more letters, the text is ready and the scan of the field's text has not answered yet and there is no earlier answer
/// to keep on screen: the ayah group shows nothing for a moment (a scan takes a few milliseconds).
class AyahSearching extends AyahGroup {
  const AyahSearching();
}

/// Two or more letters and the answer of the scan.
class AyahResults extends AyahGroup {
  const AyahResults(this.result);
  final AyahSearchResult result;
}

/// What the screen draws, immutable.
class SearchView {
  const SearchView({
    required this.surahs,
    required this.ayah,
    required this.letters,
  });

  /// The surahs in row order (at most 114).
  final List<SurahInfo> surahs;
  final AyahGroup ayah;

  /// The number of Arabic letters left in the field after the folding.
  final int letters;

  bool get nothingTyped => letters == 0;

  /// Two or more letters, ready, and neither group has a row: the «لا توجد نتائج» state.
  bool get none {
    final group = ayah;
    return letters >= 2 &&
        surahs.isEmpty &&
        group is AyahResults &&
        group.result.total == 0;
  }
}

/// What a screen reader is told once the results of [view] have settled: the labels of the groups that have rows (the two
/// headings' semantics labels), or «لا توجد نتائج»; empty when there is nothing to announce (nothing typed, the line that
/// asks for a letter, preparing, failed, a scan under way with no group yet).
String announcementOf(SearchView view) {
  final parts = <String>[];
  if (view.surahs.isNotEmpty) {
    parts.add(kSurahHeadingSemantics(view.surahs.length));
  }
  final group = view.ayah;
  if (group is AyahResults && group.result.total > 0) {
    parts.add(kAyahHeadingSemantics(group.result.total));
  }
  if (parts.isNotEmpty) return parts.join('. ');
  return view.none ? kSearchNone : '';
}

/// The screen's logic. Owned by the screen's State; disposed with it.
class SearchSession extends ChangeNotifier {
  SearchSession({
    required this.service,
    required this._surahs,
    required void Function(String text) onAnnounce,
    Duration quiet = const Duration(milliseconds: 700),
  }) {
    _gate = AnnouncementGate(quiet: quiet, send: onAnnounce);
    service.addListener(_onServiceChanged);
  }

  final SearchService service;
  final List<SurahInfo> _surahs;
  late final AnnouncementGate _gate;

  String _typed = '';
  String _folded = '';
  int _letters = 0;
  List<SurahInfo> _surahRows = const [];
  AyahGroup _ayah = const AyahHint();
  SearchView _view = const SearchView(surahs: [], ayah: AyahHint(), letters: 0);
  IndexPhase _phaseSeen = IndexPhase.notStarted;
  int _generation = 0;
  bool _disposed = false;

  SearchView get view => _view;

  /// The text of the field exactly as it was typed or pasted (never altered or trimmed).
  String get typed => _typed;

  /// The field changed: fold, answer the surah group now, start the ayah scan, drop any older scan. A change of the
  /// service's phase to `ready` runs the current query again.
  void setQuery(String typed) {
    if (_disposed || typed == _typed) return;
    _typed = typed;
    _folded = ArabicFold.query(typed);
    _letters = ArabicFold.letters(_folded);
    _surahRows = _letters == 0 ? const [] : searchSurahs(_surahs, typed);
    _refresh();
  }

  /// «إعادة المحاولة»: prepares again, then runs the current query.
  Future<void> retry() async {
    await service.retry();
    if (_disposed) return;
    // the service's own notifications have already refreshed the view; refresh only when it went by without one
    if (service.phase != _phaseSeen) _refresh();
  }

  void _onServiceChanged() {
    if (_disposed) return;
    _refresh();
  }

  /// Recomputes the ayah group for the text in the field and the phase of the service, and starts the scan when ready.
  void _refresh() {
    final generation = ++_generation;
    final phase = _phaseSeen = service.phase;
    var scan = false;
    if (_letters == 0) {
      _ayah = const AyahHint();
    } else if (_letters == 1) {
      _ayah = const AyahNeedsTwo();
    } else {
      switch (phase) {
        case IndexPhase.notStarted:
        case IndexPhase.preparing:
          _ayah = const AyahPreparing();
        case IndexPhase.failed:
          _ayah = AyahFailed(service.failure ?? const _UnknownFailure());
        case IndexPhase.ready:
          scan = true;
          // the answer to the text before this one stays on screen until the new answer replaces it
          if (_ayah is! AyahResults) _ayah = const AyahSearching();
      }
    }
    _publish();
    if (scan) unawaited(_scan(_folded, generation));
  }

  Future<void> _scan(String folded, int generation) async {
    bool current() => !_disposed && generation == _generation;
    final result = await service.searchAyat(folded, isCurrent: current);
    if (result == null || !current()) return;
    _ayah = AyahResults(result);
    _publish();
  }

  void _publish() {
    _view = SearchView(surahs: _surahRows, ayah: _ayah, letters: _letters);
    notifyListeners();
    _gate.touch(announcementOf(_view));
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    service.removeListener(_onServiceChanged);
    _gate.dispose();
    super.dispose();
  }
}

class _UnknownFailure implements Exception {
  const _UnknownFailure();

  @override
  String toString() => 'the ayah text could not be prepared';
}

/// Calls its callback once, [quiet] after the last [touch], with the latest text; nothing if the text equals the last sent,
/// and nothing for an empty text (which forgets the last sent text, so the same words are announced again later).
class AnnouncementGate {
  AnnouncementGate({required this.quiet, required this.send});

  final Duration quiet;
  final void Function(String text) send;

  Timer? _timer;
  String _latest = '';
  String? _lastSent;
  bool _disposed = false;

  void touch(String text) {
    if (_disposed) return;
    _latest = text;
    _timer?.cancel();
    _timer = Timer(quiet, _fire);
  }

  void _fire() {
    _timer = null;
    if (_disposed) return;
    if (_latest.isEmpty) {
      _lastSent = null;
      return;
    }
    if (_latest == _lastSent) return;
    _lastSent = _latest;
    send(_latest);
  }

  void dispose() {
    _disposed = true;
    _timer?.cancel();
    _timer = null;
  }
}
