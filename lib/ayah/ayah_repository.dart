import 'dart:collection';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'ayah_ref.dart';
import 'models.dart';

/// Texts longer than this many characters are decoded in another isolate so the reader never stutters.
const int kDecodeInIsolateChars = 25 * 1024;

Object? _decodeJson(String text) => jsonDecode(text);

/// Reads the bundled ayah assets: the Quran words, Tafsir al-Sa'di, the English translation and the
/// difficult words of any ayah. Each lookup loads one surah file of one kind and keeps the last
/// [cacheSize] surahs per kind.
class AyahRepository {
  AyahRepository(this._bundle);

  static const int cacheSize = 3;

  final AssetBundle _bundle;
  final _SurahCache _text = _SurahCache();
  final _SurahCache _tafsir = _SurahCache();
  final _SurahCache _translation = _SurahCache();
  final _SurahCache _gharib = _SurahCache();
  Future<List<Source>>? _sources;

  /// The Quran words of [ref], in order and unchanged. Throws [RangeError] if the file has no such ayah.
  Future<List<String>> words(AyahRef ref) async {
    final file = await _load(_text, 'text', ref.surah);
    final ayahs = file['ayahs'] as List<dynamic>;
    if (ref.ayah > ayahs.length) {
      throw RangeError.range(ref.ayah, 1, ayahs.length, 'ayah');
    }
    return (ayahs[ref.ayah - 1] as List<dynamic>).cast<String>();
  }

  /// The tafsir for [ref]; never "not found" for a real ayah. An ayah the source has no text of its own for
  /// gets the nearest earlier entry with `inherited` true. Throws [StateError] if the data does not cover it.
  Future<TafsirResult> tafsir(AyahRef ref) async {
    final file = await _load(_tafsir, 'tafsir', ref.surah);
    final entries = [
      for (final e in file['entries'] as List<dynamic>)
        TafsirEntry.fromJson(e as Map<String, dynamic>),
    ];
    for (final e in entries) {
      if (e.contains(ref.ayah)) return TafsirResult(e, inherited: false);
    }
    final without = (file['without'] as List<dynamic>? ?? const []).cast<int>();
    if (without.contains(ref.ayah)) {
      TafsirEntry? nearest;
      for (final e in entries) {
        if (e.to < ref.ayah) nearest = e;
      }
      if (nearest != null) return TafsirResult(nearest, inherited: true);
    }
    throw StateError(
      'No tafsir for ${ref.key} in ${_path('tafsir', ref.surah)}',
    );
  }

  /// The English translation (Saheeh International) of [ref].
  Future<String> translation(AyahRef ref) async {
    final file = await _load(_translation, 'translation', ref.surah);
    final ayahs = (file['ayahs'] as List<dynamic>).cast<String>();
    if (ref.ayah > ayahs.length) {
      throw RangeError.range(ref.ayah, 1, ayahs.length, 'ayah');
    }
    return ayahs[ref.ayah - 1];
  }

  /// The difficult words of [ref] with their meanings; empty when the ayah has none.
  Future<List<GharibEntry>> gharib(AyahRef ref) async {
    final file = await _load(_gharib, 'gharib', ref.surah);
    final list =
        (file['ayahs'] as Map<String, dynamic>)['${ref.ayah}']
            as List<dynamic>?;
    return [
      for (final e in list ?? const [])
        GharibEntry.fromJson(e as Map<String, dynamic>),
    ];
  }

  /// Every source of the bundled texts (labels and About credits); read once.
  Future<List<Source>> sources() => _sources ??= _readSources();

  /// The source of the gharib book [book] among [sources], or null.
  Source? sourceOfBook(List<Source> sources, int book) {
    for (final s in sources) {
      if (s.kind == 'gharib' && s.id == '$book') return s;
    }
    return null;
  }

  Future<List<Source>> _readSources() async {
    const path = 'assets/ayah/sources.json';
    try {
      final raw = await _decode(path);
      return [
        for (final s
            in (raw as Map<String, dynamic>)['sources'] as List<dynamic>)
          Source.fromJson(s as Map<String, dynamic>),
      ];
    } catch (error) {
      _sources = null; // a failed read can be retried
      throw StateError('Could not read $path: $error');
    }
  }

  static String _path(String kind, int surah) =>
      'assets/ayah/$kind/${surah.toString().padLeft(3, '0')}.json';

  Future<Map<String, dynamic>> _load(
    _SurahCache cache,
    String kind,
    int surah,
  ) {
    return cache.get(surah, () async {
      final path = _path(kind, surah);
      try {
        return await _decode(path) as Map<String, dynamic>;
      } catch (error) {
        throw StateError('Could not read $path: $error');
      }
    });
  }

  Future<Object?> _decode(String path) async {
    final text = await _bundle.loadString(path);
    return text.length > kDecodeInIsolateChars
        ? compute(_decodeJson, text)
        : _decodeJson(text);
  }
}

/// The last [AyahRepository.cacheSize] decoded surah files of one kind. Requests for the same surah
/// share one load; a failed load is forgotten so it can be retried.
class _SurahCache {
  final LinkedHashMap<int, Future<Map<String, dynamic>>> _entries =
      LinkedHashMap();

  Future<Map<String, dynamic>> get(
    int surah,
    Future<Map<String, dynamic>> Function() load,
  ) {
    final hit = _entries.remove(surah);
    if (hit != null) {
      _entries[surah] = hit; // most recently used goes last
      return hit;
    }
    final future = load();
    _entries[surah] = future;
    future.catchError((Object _) {
      _entries.remove(surah);
      return <String, dynamic>{};
    });
    while (_entries.length > AyahRepository.cacheSize) {
      _entries.remove(_entries.keys.first);
    }
    return future;
  }
}
