/// The folding of Arabic text for search (feature 011, research D2). A port of
/// `specs/011-surah-ayah-search/prototype/match_rules.py`: every number that file prints is a test.
///
/// Pure Dart, no Flutter import. The folded text is derived at run time from the stored words and is only compared,
/// never shown (Constitution I, FR-018).
library;

import 'dart:typed_data';

abstract final class ArabicFold {
  /// The small alef and the seatless hamza: the two SOFT characters of a folded stored word.
  static const String dagger = 'ٰ';
  static const String hamza = 'ء';

  /// A typed ؤ and a typed ئ inside a folded query (never mixed with و / ي).
  static const String seatWaw = '\u0001';
  static const String seatYeh = '\u0002';

  static const int _space = 0x20;
  static const int _daggerUnit = 0x670;
  static const int _hamzaUnit = 0x621;
  static const int _seatWawUnit = 0x01;
  static const int _seatYehUnit = 0x02;
  static const int _alef = 0x627;

  /// The characters a folded stored word may hold, besides the two soft ones.
  static const String _letters = 'ابتثجحخدذرزسشصضطظعغفقكلمنهوي';

  /// code unit below U+0700 -> its folded code unit; 0 means "gone" (tashkeel, marks, tatweel, signs, spaces, anything
  /// that is not a letter of the Quran text). Every folded value that is not [_hamzaUnit] or [_daggerUnit] is a letter.
  static final Uint16List _table = _buildTable();

  static Uint16List _buildTable() {
    final table = Uint16List(0x700);
    for (final unit in _letters.codeUnits) {
      table[unit] = unit;
    }
    table[_hamzaUnit] = _hamzaUnit;
    table[_daggerUnit] = _daggerUnit;
    // The four alef forms are one letter.
    for (final unit in const [0x623, 0x625, 0x622, 0x671]) {
      table[unit] = _alef;
    }
    table[0x624] = 0x648; // ؤ -> و
    table[0x626] = 0x64A; // ئ -> ي
    table[0x649] = 0x64A; // ى -> ي
    table[0x6CC] = 0x64A; // Persian yeh -> ي
    table[0x629] = 0x647; // ة -> ه
    table[0x6A9] = 0x643; // Persian kaf -> ك
    table[0x6E7] = 0x64A; // small high yeh is a real yeh
    table[0x6E8] = 0x646; // small high noon is a real noon
    table[0x654] = _hamzaUnit; // the hamza signs are a seatless hamza
    table[0x655] = _hamzaUnit;
    return table;
  }

  static bool _isSoft(int folded) =>
      folded == _hamzaUnit || folded == _daggerUnit;

  /// One STORED word folded (research D2, "The stored side"): letters folded, tashkeel/marks/tatweel/signs/spaces gone,
  /// `ء` (and the hamza signs) and `ٰ` kept as soft characters. Never empty for a stored word of the bundled text.
  static String word(String stored) {
    final units = stored.codeUnits;
    final out = Uint16List(units.length);
    var n = 0;
    for (var i = 0; i < units.length; i++) {
      final unit = units[i];
      if (unit >= 0x700) continue;
      final folded = _table[unit];
      if (folded != 0) out[n++] = folded;
    }
    return String.fromCharCodes(out, 0, n);
  }

  /// The words of one stored ayah folded and joined by one space (word k of the result is word k of [words]).
  static String ayah(List<String> words) {
    final b = StringBuffer();
    for (var k = 0; k < words.length; k++) {
      if (k > 0) b.writeCharCode(_space);
      b.write(word(words[k]));
    }
    return b.toString();
  }

  /// The typed text folded for matching: letters, single spaces, [seatWaw], [seatYeh]; every other character is a word
  /// break or vanishes; trimmed. `query('أَحۡمَد')` is `'احمد'`, `query('﴿ قل ٢ هو ﴾')` is `'قل هو'`.
  static String query(String typed) {
    final units = typed.codeUnits;
    final out = Uint16List(units.length);
    var n = 0;
    var space = false;
    for (var i = 0; i < units.length; i++) {
      final unit = units[i];
      if (unit == 0x624 || unit == 0x626) {
        out[n++] = unit == 0x624 ? _seatWawUnit : _seatYehUnit;
        space = false;
        continue;
      }
      final folded = unit < 0x700 ? _table[unit] : 0;
      if (folded != 0 && !_isSoft(folded)) {
        out[n++] = folded;
        space = false;
      } else if (_isSoft(folded) || _vanishes(unit)) {
        continue; // a typed hamza or dagger, a mark, tatweel, an invisible control: gone, no break
      } else if (!space && n > 0) {
        out[n++] = _space;
        space = true;
      }
    }
    if (n > 0 && out[n - 1] == _space) n--;
    return String.fromCharCodes(out, 0, n);
  }

  /// Tatweel, the tashkeel block, the Quranic marks and the invisible controls: they vanish from a query without a break.
  static bool _vanishes(int unit) =>
      unit == 0x640 ||
      (unit >= 0x64B && unit <= 0x65F) ||
      (unit >= 0x6D6 && unit <= 0x6ED) ||
      (unit >= 0x200B && unit <= 0x200F) ||
      unit == 0xFEFF;

  /// The number of letters of a folded query (its characters that are not a space).
  static int letters(String foldedQuery) {
    var count = 0;
    for (final unit in foldedQuery.codeUnits) {
      if (unit != _space) count++;
    }
    return count;
  }

  /// The `RegExp` that finds [foldedQuery] in a folded text (research D2, "The pattern"). Throws [ArgumentError] when
  /// [foldedQuery] has no letter.
  static RegExp pattern(String foldedQuery) {
    if (letters(foldedQuery) == 0) {
      throw ArgumentError.value(foldedQuery, 'foldedQuery', 'has no letter');
    }
    const soft = '$dagger$hamza';
    final b = StringBuffer();
    for (final unit in foldedQuery.codeUnits) {
      if (unit == _space) {
        b.write('[$soft ]*');
        continue;
      }
      switch (unit) {
        case _alef: // an alef, the و of «الصلوٰة», or the small alef itself
          b.write('(?:ا|و$dagger|$dagger)');
        case _seatWawUnit: // a typed ؤ: a waw or a seatless hamza
          b.write('[و$hamza]');
        case _seatYehUnit: // a typed ئ: a yeh or a seatless hamza
          b.write('[ي$hamza]');
        default:
          b.write(RegExp.escape(String.fromCharCode(unit)));
      }
      b.write('[$soft]*');
    }
    return RegExp(b.toString());
  }

  /// A surah name folded for the surah search: like [word] but `ء` and `ٰ` removed and ؤ/ئ as و/ي.
  static String surahKey(String name) =>
      word(name).replaceAll(hamza, '').replaceAll(dagger, '');
}
