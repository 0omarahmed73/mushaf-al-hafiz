// Which words of an ayah a search row shows (feature 011, T008; spec FR-011, FR-012; research D6). Pure Dart: the widget supplies
// the measuring (`fits`, a three-line layout in the row's width), the tests a character budget.

/// The run of words a snippet shows: the words `from` to `to` of the ayah, both inclusive, never cut inside a word.
class SnippetWords {
  const SnippetWords({
    required this.from,
    required this.to,
    required this.cutBefore,
    required this.cutAfter,
  });

  /// The first word shown (inclusive).
  final int from;

  /// The last word shown (inclusive).
  final int to;

  /// Words were left out before [from]: the row draws «…» first.
  final bool cutBefore;

  /// Words were left out after [to]: the row draws «…» last.
  final bool cutAfter;

  @override
  bool operator ==(Object other) =>
      other is SnippetWords &&
      other.from == from &&
      other.to == to &&
      other.cutBefore == cutBefore &&
      other.cutAfter == cutAfter;

  @override
  int get hashCode => Object.hash(from, to, cutBefore, cutAfter);

  @override
  String toString() =>
      'SnippetWords($from..$to, cutBefore: $cutBefore, cutAfter: $cutAfter)';
}

/// The run of whole, consecutive words around the first matched word of an ayah of `matched.length` words (one flag per word).
///
/// The run starts as the first matched word alone and grows one whole word at a time, the word after it first and then the
/// word before it, alternately (only the other side once one side has no word left), and **stops at the first word that does
/// not fit**. So the first matched word is always inside, a word is never cut, and an ayah that fits is returned whole, with
/// both cut flags false. A first matched word that is wider than [fits] allows is still returned, alone.
///
/// [fits] says whether the run `from..to` (both inclusive) is acceptable; it must be monotone: a run that fits is still
/// fitting after words are taken away from it. The runs asked about are nested (each holds the one before it), so the answer is
/// found by a binary search, at most `ceil(log2(n))` calls of [fits]: 7 for the 128 words of Al-Baqarah 2:282.
///
/// "After" and "before" are in the order of the words (reading order); [matched] with no `true` makes the first word the start
/// (the search never gives such an ayah: a query that matches an ayah marks at least one word of it).
SnippetWords snippetOf(
  List<bool> matched, {
  required bool Function(int from, int to) fits,
}) {
  final n = matched.length;
  if (n == 0) {
    throw ArgumentError.value(
      matched,
      'matched',
      'an ayah has at least one word',
    );
  }
  final first = matched.indexOf(true);
  final anchor = first < 0 ? 0 : first;

  // The run after `steps` growth steps: the word after, the word before, alternately; the other side when one is used up.
  (int, int) window(int steps) {
    final afterRoom = n - 1 - anchor;
    final beforeRoom = anchor;
    var after = (steps + 1) ~/ 2;
    var before = steps ~/ 2;
    if (after > afterRoom) {
      before += after - afterRoom;
      after = afterRoom;
    }
    if (before > beforeRoom) {
      after += before - beforeRoom;
      before = beforeRoom;
    }
    return (anchor - before, anchor + after);
  }

  // The largest number of steps whose run fits; zero steps (the matched word alone) is returned even when it does not.
  var low = 0;
  var high = n - 1;
  while (low < high) {
    final mid = (low + high + 1) ~/ 2;
    final (from, to) = window(mid);
    if (fits(from, to)) {
      low = mid;
    } else {
      high = mid - 1;
    }
  }
  final (from, to) = window(low);
  return SnippetWords(
    from: from,
    to: to,
    cutBefore: from > 0,
    cutAfter: to < n - 1,
  );
}
