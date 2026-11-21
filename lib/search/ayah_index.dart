/// The in-memory index of the Quran text that the ayah search scans (feature 011, research D1 and D3; data-model.md
/// "AyahIndex"). Derived at run time from the stored text by the folding of [ArabicFold], validated at every build,
/// never shown (Constitution I, FR-018).
library;

import 'dart:convert';
import 'dart:typed_data';

import '../ayah/ayah_ref.dart';
import '../mushaf/models.dart';
import 'arabic_fold.dart';

/// The index could not be built: a file is missing its shape, a surah is out of order, a word folds to nothing or the
/// counts differ from the Mushaf's data. The ayah group then shows the failure line (data-model.md "Validation").
class SearchIndexError implements Exception {
  const SearchIndexError(this.message);
  final String message;

  @override
  String toString() => 'SearchIndexError: $message';
}

class AyahIndex {
  AyahIndex({
    required this.chunks,
    required this.ayahStart,
    required this.surahFirst,
    required this.stored,
  });

  static const int ayahsPerChunk = 800;

  /// The folded ayat in Mushaf order, [ayahsPerChunk] to a chunk, each ayah followed by a line break (8 chunks).
  final List<String> chunks;

  /// The offset of ayah *i* inside `chunks[i ~/ ayahsPerChunk]`; 6,237 entries, the last closes the last chunk.
  final Int32List ayahStart;

  /// `surahFirst[s - 1]` is the index of the first ayah of surah *s* (1..114); `surahFirst[114]` is the ayah count (115
  /// entries).
  final Int32List surahFirst;

  /// The stored words of ayah *i* joined by `\n` (a stored word never holds a line break), unchanged.
  final List<String> stored;

  int get ayahCount => stored.length;

  /// About 2.6 MB for the bundled text: two bytes a UTF-16 unit of the folded text and of the stored words, and the tables.
  int get estimatedBytes {
    var units = 0;
    for (final chunk in chunks) {
      units += chunk.length;
    }
    for (final words in stored) {
      units += words.length;
    }
    return 2 * units + ayahStart.lengthInBytes + surahFirst.lengthInBytes;
  }

  /// The ayah at [index] (0 .. ayahCount - 1, Mushaf order). Throws [RangeError] outside it.
  AyahRef refOf(int index) {
    RangeError.checkValidIndex(index, stored);
    var low = 0,
        high = surahFirst.length - 2; // surah numbers 1..114 are 0..113 here
    while (low < high) {
      final mid = (low + high + 1) >> 1;
      if (surahFirst[mid] <= index) {
        low = mid;
      } else {
        high = mid - 1;
      }
    }
    return AyahRef(low + 1, index - surahFirst[low] + 1);
  }

  /// The position of [ref] in Mushaf order. Throws [RangeError] for an ayah that does not exist.
  int indexOf(AyahRef ref) {
    if (ref.surah < 1 || ref.surah > surahFirst.length - 1) {
      throw RangeError.range(ref.surah, 1, surahFirst.length - 1, 'surah');
    }
    final first = surahFirst[ref.surah - 1];
    final count = surahFirst[ref.surah] - first;
    if (ref.ayah < 1 || ref.ayah > count) {
      throw RangeError.range(ref.ayah, 1, count, 'ayah');
    }
    return first + ref.ayah - 1;
  }

  /// The stored words of ayah [index], unchanged.
  List<String> storedWords(int index) => stored[index].split('\n');

  int _end(int index) {
    final c = index ~/ ayahsPerChunk;
    final next = index + 1;
    return next < ayahCount && next ~/ ayahsPerChunk == c
        ? ayahStart[next]
        : chunks[c].length;
  }

  /// The folded text of ayah [index] (no trailing line break).
  String foldedAyah(int index) => chunks[index ~/ ayahsPerChunk].substring(
    ayahStart[index],
    _end(index) - 1,
  );

  /// The ayat of chunk [chunk] whose folded text contains [pattern], once each, in ascending order.
  List<int> scanChunk(int chunk, RegExp pattern) {
    final text = chunks[chunk];
    final base = chunk * ayahsPerChunk;
    final count = (ayahCount - base < ayahsPerChunk
        ? ayahCount - base
        : ayahsPerChunk);
    final hits = <int>[];
    var from = 0;
    var k = 0;
    while (from < text.length) {
      final it = pattern.allMatches(text, from).iterator;
      if (!it.moveNext()) break;
      final at = it.current.start;
      while (k + 1 < count && ayahStart[base + k + 1] <= at) {
        k++;
      }
      hits.add(base + k);
      from = k + 1 < count
          ? ayahStart[base + k + 1]
          : text.length; // the rest of this ayah cannot add a hit
    }
    return hits;
  }

  /// The words of ayah [index] that [pattern] matches: a flag per stored word (none is true when nothing matches).
  List<bool> matchedWords(int index, RegExp pattern) {
    final words = storedWords(index);
    final matched = List<bool>.filled(words.length, false);
    final folded = foldedAyah(index);
    final spans = [
      for (final m in pattern.allMatches(folded)) (m.start, m.end),
    ];
    if (spans.isEmpty) return matched;
    var offset = 0;
    var s = 0;
    for (var w = 0; w < words.length; w++) {
      final end = offset + ArabicFold.word(words[w]).length;
      while (s < spans.length && spans[s].$2 <= offset) {
        s++;
      }
      // spans[s] is the first match that ends after this word starts; it touches the word when it starts before it ends
      if (s < spans.length && spans[s].$1 < end) matched[w] = true;
      offset = end + 1; // the space between two words
    }
    return matched;
  }
}

/// Adds the surah files one by one and builds the index. A surah is opened with [openSurah] (its text is decoded and
/// checked), its ayat are added one at a time with [addAyah] (so the caller may yield between two of them) and the surah
/// is closed with [closeSurah]; [addSurah] does the three for a whole file.
class AyahIndexBuilder {
  /// The words the bundled text has (data-model.md "Validation").
  static const int expectedWords = 77432;

  final List<String> _chunks = [];
  final List<int> _starts = [];
  final List<int> _surahFirst = [];
  final List<String> _stored = [];
  final StringBuffer _chunk = StringBuffer();
  int _chunkLength = 0;
  int _words = 0;
  int _surahs = 0;
  int _open = 0; // the surah being added, 0 when none
  List<List<String>>? _pending;
  int _added = 0; // ayat of the open surah added so far

  /// Starts surah [surah] from the text of its file `assets/ayah/text/NNN.json` and returns its ayat (the stored words
  /// of each); add them with [addAyah] in order, then call [closeSurah]. Throws [SearchIndexError] on a surah out of order
  /// or a malformed file.
  List<List<String>> openSurah(int surah, String json) {
    if (_open != 0) throw SearchIndexError('surah $_open is still open');
    if (surah != _surahs + 1) {
      throw SearchIndexError(
        'surah $surah added out of order (expected ${_surahs + 1})',
      );
    }
    final List<List<String>> ayat;
    try {
      final decoded = jsonDecode(json);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('not an object');
      }
      if (decoded['surah'] != surah) {
        throw FormatException('the file is not surah $surah');
      }
      final list = decoded['ayahs'];
      if (list is! List<dynamic> || list.isEmpty) {
        throw const FormatException('no ayat');
      }
      ayat = [
        for (final a in list)
          if (a is List<dynamic> && a.isNotEmpty && a.every((w) => w is String))
            a.cast<String>()
          else
            throw const FormatException('an ayah is not a list of words'),
      ];
    } on FormatException catch (e) {
      throw SearchIndexError('surah $surah: ${e.message}');
    }
    _surahFirst.add(_stored.length);
    _open = surah;
    _pending = ayat;
    _added = 0;
    return ayat;
  }

  /// Folds and adds the next ayah of the open surah. Throws [SearchIndexError] for a word that folds to nothing or holds a
  /// line break.
  void addAyah(List<String> words) {
    if (_open == 0) throw const SearchIndexError('no surah is open');
    final number = _added + 1;
    for (var k = 0; k < words.length; k++) {
      final w = words[k];
      if (w.contains('\n')) {
        throw SearchIndexError(
          '$_open:$number word ${k + 1} holds a line break',
        );
      }
      if (ArabicFold.word(w).isEmpty) {
        throw SearchIndexError('$_open:$number word ${k + 1} folds to nothing');
      }
    }
    final folded = ArabicFold.ayah(words);
    _starts.add(_chunkLength);
    _chunk
      ..write(folded)
      ..write('\n');
    _chunkLength += folded.length + 1;
    _stored.add(words.join('\n'));
    _words += words.length;
    _added = number;
    if (_starts.length % AyahIndex.ayahsPerChunk == 0) _flushChunk();
  }

  void _flushChunk() {
    _chunks.add(_chunk.toString());
    _chunk.clear();
    _chunkLength = 0;
  }

  /// Ends the open surah; throws [SearchIndexError] when not every ayat of the file was added.
  void closeSurah() {
    final pending = _pending;
    if (_open == 0 || pending == null) {
      throw const SearchIndexError('no surah is open');
    }
    if (_added != pending.length) {
      throw SearchIndexError(
        'surah $_open: $_added of ${pending.length} ayat added',
      );
    }
    _surahs = _open;
    _open = 0;
    _pending = null;
  }

  /// Decodes [json] (the text of `assets/ayah/text/NNN.json`) and adds its ayat. Throws [SearchIndexError] on a surah
  /// out of order, a malformed file or a word that folds to nothing.
  void addSurah(int surah, String json) {
    for (final words in openSurah(surah, json)) {
      addAyah(words);
    }
    closeSurah();
  }

  /// Validates against [meta] (114 surahs, 6,236 ayat, the per-surah counts) and returns the index; throws
  /// [SearchIndexError] otherwise.
  AyahIndex build(MushafMeta meta) {
    if (_open != 0) throw SearchIndexError('surah $_open is still open');
    if (_surahs != MushafMeta.surahCount) {
      throw SearchIndexError(
        '$_surahs surahs added, ${MushafMeta.surahCount} expected',
      );
    }
    if (meta.surahs.length != MushafMeta.surahCount) {
      throw SearchIndexError(
        'the Mushaf data has ${meta.surahs.length} surahs',
      );
    }
    final surahFirst = Int32List(MushafMeta.surahCount + 1);
    for (var s = 1; s <= MushafMeta.surahCount; s++) {
      final first = _surahFirst[s - 1];
      final end = s < MushafMeta.surahCount ? _surahFirst[s] : _stored.length;
      if (end - first != meta.surah(s).ayahs) {
        throw SearchIndexError(
          'surah $s has ${end - first} ayat, the Mushaf data says ${meta.surah(s).ayahs}',
        );
      }
      surahFirst[s - 1] = first;
    }
    surahFirst[MushafMeta.surahCount] = _stored.length;
    var expectedAyat = 0;
    for (final s in meta.surahs) {
      expectedAyat += s.ayahs;
    }
    if (_stored.length != expectedAyat) {
      throw SearchIndexError('${_stored.length} ayat, $expectedAyat expected');
    }
    if (_words != expectedWords) {
      throw SearchIndexError('$_words words, $expectedWords expected');
    }
    if (_chunkLength > 0) _flushChunk();
    final ayahStart = Int32List(_stored.length + 1);
    for (var i = 0; i < _starts.length; i++) {
      ayahStart[i] = _starts[i];
    }
    ayahStart[_stored.length] = _chunks.last.length;
    for (var i = 0; i + 1 < _stored.length; i++) {
      final sameChunk =
          (i + 1) ~/ AyahIndex.ayahsPerChunk == i ~/ AyahIndex.ayahsPerChunk;
      if (sameChunk && ayahStart[i + 1] <= ayahStart[i]) {
        throw SearchIndexError('the folded text of ayah ${i + 1} is empty');
      }
    }
    return AyahIndex(
      chunks: List.unmodifiable(_chunks),
      ayahStart: ayahStart,
      surahFirst: surahFirst,
      stored: List.unmodifiable(_stored),
    );
  }
}
