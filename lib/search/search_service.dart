/// The service behind the ayah group of the search (feature 011, research D1 and D5; data-model.md "Service state").
///
/// One per run, created at launch and reading nothing (FR-022). The first `prepare()` reads the 114 files of the stored
/// text, folds them in slices of a few milliseconds on the UI isolate and keeps the [AyahIndex] for the rest of the run.
/// A search scans the folded text one chunk at a time with a yield between chunks, and keeps the first
/// [AyahSearchResult.maxRows] hits.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../ayah/ayah_ref.dart';
import '../mushaf/models.dart';
import 'arabic_fold.dart';
import 'ayah_index.dart';
import 'search_trace.dart';

/// Where the preparation of the ayah text stands.
enum IndexPhase {
  /// Created at launch; nothing read.
  notStarted,

  /// Reading, decoding and folding the 114 files in slices.
  preparing,

  /// The index is held for the rest of the run.
  ready,

  /// A file could not be read or the validation failed; [SearchService.failure] holds the error.
  failed,
}

/// One ayah found by a search: where it is, its stored words (unchanged) and which of them matched.
class AyahHit {
  const AyahHit({
    required this.ref,
    required this.page,
    required this.words,
    required this.matched,
  });

  final AyahRef ref;

  /// Where the ayah begins (`MushafMeta.pageOfAyah`).
  final int page;

  /// The stored words, unchanged.
  final List<String> words;

  /// One flag per word.
  final List<bool> matched;
}

/// The answer to one query: every ayah that matches is counted, the first [maxRows] are kept.
class AyahSearchResult {
  const AyahSearchResult({required this.total, required this.hits});

  /// All ayat that match.
  final int total;

  /// The first [maxRows] in Mushaf order.
  final List<AyahHit> hits;

  static const int maxRows = 100;

  bool get tooMany => total > hits.length;
}

/// One per run. Creating it reads nothing (FR-022).
class SearchService extends ChangeNotifier {
  SearchService({
    required AssetBundle this._bundle,
    required Future<MushafMeta> Function() meta,
    Future<void> Function()? yieldTurn,
    this._slice = const Duration(milliseconds: 8),
    void Function(String line)? trace,
  }) : _metaLoader = meta,
       _yield = yieldTurn ?? _defaultYield,
       _trace = trace ?? (SearchTrace.enabled ? SearchTrace.emit : null);

  /// A service that is already `ready` over [index] (tests of the screen). It has no bundle: `prepare` and `retry` do
  /// nothing.
  SearchService.prepared(
    AyahIndex index,
    MushafMeta meta, {
    Future<void> Function()? yieldTurn,
  }) : _bundle = null,
       _metaLoader = null,
       _yield = yieldTurn ?? _defaultYield,
       _slice = Duration.zero,
       _trace = null,
       _index = index,
       _meta = meta,
       _phase = IndexPhase.ready;

  static Future<void> _defaultYield() => Future<void>.delayed(Duration.zero);

  final AssetBundle? _bundle;
  final Future<MushafMeta> Function()? _metaLoader;
  final Future<void> Function() _yield;
  final Duration _slice;

  /// Receives the `SEARCH prepare` line (research D9): the log under `--dart-define=SEARCH_TRACE=true`, nothing otherwise; a test
  /// passes its own.
  final void Function(String line)? _trace;

  IndexPhase _phase = IndexPhase.notStarted;
  Object? _failure;
  AyahIndex? _index;
  MushafMeta? _meta;
  Future<void>? _preparing;
  bool _disposed = false;

  IndexPhase get phase => _phase;

  /// The error that ended the last preparation, while the phase is `failed`.
  Object? get failure => _failure;

  /// Starts preparing once; does nothing while `preparing` or `ready` (the running work is shared); starts again after
  /// `failed`. The phase is `preparing` when the call returns. The future completes when the preparation ends, `ready` or
  /// `failed`; it never throws.
  Future<void> prepare() {
    switch (_phase) {
      case IndexPhase.preparing:
        return _preparing!;
      case IndexPhase.ready:
        return Future<void>.value();
      case IndexPhase.notStarted:
      case IndexPhase.failed:
        _failure = null;
        _setPhase(IndexPhase.preparing);
        return _preparing = _prepare();
    }
  }

  /// «إعادة المحاولة»: prepares again after a failure (the same as [prepare]).
  Future<void> retry() => prepare();

  void _setPhase(IndexPhase phase) {
    _phase = phase;
    if (!_disposed) notifyListeners();
  }

  Future<void> _prepare() async {
    try {
      // Only measured when something listens (SEARCH_TRACE or a test): the whole preparation and the pieces it was cut into.
      final trace = _trace;
      final whole = trace == null ? null : (Stopwatch()..start());
      var slices = 1;
      final bundle = _bundle!;
      final meta = await _metaLoader!();
      final builder = AyahIndexBuilder();
      final slice = Stopwatch()..start();
      for (var surah = 1; surah <= MushafMeta.surahCount; surah++) {
        final text = await bundle.loadString(_textPath(surah), cache: false);
        slice.reset(); // waiting for a file is not work on this isolate
        for (final words in builder.openSurah(surah, text)) {
          builder.addAyah(words);
          if (slice.elapsed >= _slice) {
            await _yield();
            slices++;
            slice.reset();
          }
        }
        builder.closeSurah();
      }
      final index = builder.build(meta);
      _index = index;
      _meta = meta;
      if (trace != null) {
        trace(SearchTrace.prepareLine(whole!.elapsedMilliseconds, slices));
      }
      _setPhase(IndexPhase.ready);
    } catch (error) {
      _failure = error;
      _setPhase(IndexPhase.failed);
    }
  }

  static String _textPath(int surah) =>
      'assets/ayah/text/${surah.toString().padLeft(3, '0')}.json';

  /// Scans the folded text for [foldedQuery] (at least two letters), a chunk at a time with a yield between chunks.
  /// Returns null when [isCurrent] became false (a newer query exists) or the service is not ready; a query with fewer
  /// than two letters gets an empty result (the session does not ask). Never throws for a query.
  Future<AyahSearchResult?> searchAyat(
    String foldedQuery, {
    required bool Function() isCurrent,
  }) async {
    final index = _index;
    final meta = _meta;
    if (_phase != IndexPhase.ready || index == null || meta == null) {
      return null;
    }
    const empty = AyahSearchResult(total: 0, hits: []);
    if (ArabicFold.letters(foldedQuery) < 2) return empty;
    final RegExp pattern;
    try {
      pattern = ArabicFold.pattern(foldedQuery);
    } on Object {
      return empty;
    }
    var total = 0;
    final kept = <int>[];
    final chunks = index.chunks.length;
    for (var chunk = 0; chunk < chunks; chunk++) {
      if (!isCurrent()) return null;
      final hits = index.scanChunk(chunk, pattern);
      total += hits.length;
      for (
        var h = 0;
        h < hits.length && kept.length < AyahSearchResult.maxRows;
        h++
      ) {
        kept.add(hits[h]);
      }
      if (chunk + 1 < chunks) await _yield();
    }
    if (!isCurrent()) return null;
    return AyahSearchResult(
      total: total,
      hits: [
        for (final i in kept)
          () {
            final ref = index.refOf(i);
            return AyahHit(
              ref: ref,
              page: meta.pageOfAyah(ref.surah, ref.ayah),
              words: index.storedWords(i),
              matched: index.matchedWords(i, pattern),
            );
          }(),
      ],
    );
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    super.dispose();
  }
}
