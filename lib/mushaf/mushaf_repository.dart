import 'dart:collection';
import 'dart:convert';

import 'package:flutter/services.dart';

import 'models.dart';

/// Loads the bundled Mushaf assets. Keeps the last [cacheSize] pages in memory.
class MushafRepository {
  MushafRepository(this._bundle);

  static const int cacheSize = 8;

  final AssetBundle _bundle;
  final LinkedHashMap<int, PageData> _cache = LinkedHashMap();
  MushafMeta? _meta;

  Future<MushafMeta> loadMeta() async {
    final cached = _meta;
    if (cached != null) return cached;
    final text = await _bundle.loadString('assets/mushaf/meta.json');
    return _meta = MushafMeta.fromJson(jsonDecode(text) as Map<String, dynamic>);
  }

  /// The page if it is already in the cache (no I/O, no reordering): what a page that is built at rest uses to show its
  /// text in its first frame (feature 010).
  PageData? peek(int page) => _cache[page];

  /// Loads [page] into the cache for later and swallows every error: a neighbour that cannot be read is asked again, and
  /// reported, when the reader really needs it (feature 010).
  Future<void> prefetch(int page) async {
    if (page < 1 || page > MushafMeta.pageCount || _cache.containsKey(page)) return;
    try {
      await loadPage(page);
    } catch (_) {
      // Surfaces when the page itself is asked for.
    }
  }

  final Map<int, Future<PageData>> _inflight = {};

  /// The raw text of the page files read only to learn a first word, kept until that page is loaded itself, so every
  /// page file is read once (feature 010).
  final Map<int, String> _readAhead = {};

  /// Throws [RangeError] outside 1..604.
  Future<PageData> loadPage(int page) async {
    if (page < 1 || page > MushafMeta.pageCount) {
      throw RangeError.range(page, 1, MushafMeta.pageCount, 'page');
    }
    final hit = _cache.remove(page);
    if (hit != null) {
      _cache[page] = hit; // most recently used goes last
      return hit;
    }
    // Two askers of the same page (a prefetch and the page's own widget) share one read.
    // The callback must not return the removed future: whenComplete would then wait for its own result.
    return _inflight.putIfAbsent(
      page,
      () => _read(page).whenComplete(() {
        _inflight.remove(page);
      }),
    );
  }

  Future<PageData> _read(int page) async {
    final text = _readAhead.remove(page) ?? await _bundle.loadString(_pageAsset(page));
    final loaded = PageData.fromJson(jsonDecode(text) as Map<String, dynamic>);
    final words = [for (final l in loaded.lines) ...l.words];
    if (words.isNotEmpty) {
      _firstWords[page] = (words.first.surah, words.first.ayah);
    }
    final data = loaded.withEndMarkers(await _endMarkers(page, words));
    _cache[page] = data;
    while (_cache.length > cacheSize) {
      _cache.remove(_cache.keys.first);
    }
    return data;
  }

  static String _pageAsset(int page) =>
      'assets/mushaf/pages/p${page.toString().padLeft(3, '0')}.json';

  /// (surah, ayah) of the first word of the pages seen so far: what the last word of the page before needs.
  final Map<int, (int, int)> _firstWords = {};

  /// The ids of the words of [page] that end their ayah: a word does when the next word in Mushaf order belongs to
  /// another ayah, and the last word of a page when the first word of the next page does (or when it is the last
  /// word of the Mushaf). Best effort: if the next page cannot be read the last word is simply not marked.
  Future<Set<int>> _endMarkers(int page, List<MushafWord> words) async {
    final ids = <int>{};
    for (var i = 0; i + 1 < words.length; i++) {
      final a = words[i], b = words[i + 1];
      if (a.surah != b.surah || a.ayah != b.ayah) ids.add(a.id);
    }
    if (words.isEmpty) return ids;
    final last = words.last;
    if (page == MushafMeta.pageCount) {
      ids.add(last.id);
    } else {
      final next = await _firstWordOf(page + 1);
      if (next != null && next != (last.surah, last.ayah)) ids.add(last.id);
    }
    return ids;
  }

  /// (surah, ayah) of the first word of [page], from a page already loaded, one seen before, or one small read of
  /// its file (not kept as a page). Null when it cannot be had; never throws.
  Future<(int, int)?> _firstWordOf(int page) async {
    final known = _firstWords[page] ?? _cache[page]?.firstWordRef;
    if (known != null) return known;
    try {
      final text = await _bundle.loadString(_pageAsset(page));
      // This page is probably the next one to load: keep its text so that load does not read the file again.
      _readAhead[page] = text;
      while (_readAhead.length > 4) {
        _readAhead.remove(_readAhead.keys.first);
      }
      final json = jsonDecode(text) as Map<String, dynamic>;
      for (final line in json['lines'] as List<dynamic>) {
        final words = (line as Map<String, dynamic>)['words'] as List<dynamic>;
        if (words.isEmpty) continue;
        final k = ((words.first as Map<String, dynamic>)['k'] as String).split(':');
        return _firstWords[page] = (int.parse(k[0]), int.parse(k[1]));
      }
    } catch (_) {
      // The next page is not there (a bundle with fewer pages, a bad file): this page loads without it.
    }
    return null;
  }
}

extension on PageData {
  /// (surah, ayah) of the page's first word.
  (int, int)? get firstWordRef {
    for (final l in lines) {
      if (l.words.isNotEmpty) return (l.words.first.surah, l.words.first.ayah);
    }
    return null;
  }
}
