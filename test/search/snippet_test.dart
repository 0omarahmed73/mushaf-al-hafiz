// The snippet of an ayah row: a run of whole, consecutive stored words around the first matched word (feature 011, T008;
// spec FR-011, FR-012, SC-009; research D6). The window grows from the first matched word one whole word at a time, the
// following word first and then the preceding one, alternately, and stops at the first word that does not fit.
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:mushaf/ayah/ayah_ref.dart';
import 'package:mushaf/search/arabic_fold.dart';
import 'package:mushaf/search/ayah_index.dart';
import 'package:mushaf/search/snippet.dart';

import '../support/search_harness.dart';

/// The words of a test ayah: `w<i>` padded with letters to the given lengths.
List<String> _words(List<int> lengths) => [
  for (var i = 0; i < lengths.length; i++) 'w$i'.padRight(lengths[i], 'x'),
];

/// A character-budget `fits`: the run `from..to` joined by single spaces is at most [budget] characters.
bool Function(int, int) _budget(List<String> words, int budget) =>
    (from, to) => words.sublist(from, to + 1).join(' ').length <= budget;

List<bool> _flags(int n, Set<int> on) => [
  for (var i = 0; i < n; i++) on.contains(i),
];

/// The slow, obvious reading of the rule: one word at a time (the following word, then the preceding one, alternately; the
/// other side when one has no word left), and stop at the first word that does not fit.
SnippetWords _oracle(List<bool> matched, bool Function(int, int) fits) {
  final n = matched.length;
  final anchor = matched.contains(true) ? matched.indexOf(true) : 0;
  var from = anchor;
  var to = anchor;
  var afterNext = true;
  while (to - from + 1 < n) {
    var nf = from;
    var nt = to;
    final canAfter = to + 1 < n;
    final canBefore = from - 1 >= 0;
    if ((afterNext && canAfter) || !canBefore) {
      nt = to + 1;
    } else {
      nf = from - 1;
    }
    if (!fits(nf, nt)) break;
    from = nf;
    to = nt;
    afterNext = !afterNext;
  }
  return SnippetWords(
    from: from,
    to: to,
    cutBefore: from > 0,
    cutAfter: to < n - 1,
  );
}

void expectRun(
  SnippetWords s,
  int from,
  int to, {
  required bool before,
  required bool after,
  String? reason,
}) {
  expect(
    [s.from, s.to, s.cutBefore, s.cutAfter],
    [from, to, before, after],
    reason: reason ?? 'from, to, cutBefore, cutAfter',
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('snippetOf over a character budget', () {
    test(
      'an ayah that fits is shown whole, with no mark for left-out words',
      () {
        final words = _words([3, 3, 3]);
        final s = snippetOf(_flags(3, {1}), fits: _budget(words, 100));
        expectRun(s, 0, 2, before: false, after: false);
      },
    );

    test('an ayah of one word is that word', () {
      final s = snippetOf([true], fits: (from, to) => true);
      expectRun(s, 0, 0, before: false, after: false);
    });

    test('the run starts at the first matched word, even when later words match too', () {
      final words = _words([3, 3, 3, 3, 3]);
      // A budget of exactly one word: only the first matched word is shown.
      final s = snippetOf(_flags(5, {2, 4}), fits: _budget(words, 3));
      expectRun(s, 2, 2, before: true, after: true);
    });

    test('it grows by whole words, the following word first and then the preceding one, alternately', () {
      final words = _words([2, 2, 2, 2, 2, 2, 2]);
      final matched = _flags(7, {3});
      // Each word is 2 characters, a run of k words is 2k + (k - 1) characters.
      expectRun(
        snippetOf(matched, fits: _budget(words, 2)),
        3,
        3,
        before: true,
        after: true,
        reason: '1 word',
      );
      expectRun(
        snippetOf(matched, fits: _budget(words, 5)),
        3,
        4,
        before: true,
        after: true,
        reason: '2 words',
      );
      expectRun(
        snippetOf(matched, fits: _budget(words, 8)),
        2,
        4,
        before: true,
        after: true,
        reason: '3 words',
      );
      expectRun(
        snippetOf(matched, fits: _budget(words, 11)),
        2,
        5,
        before: true,
        after: true,
        reason: '4 words',
      );
      expectRun(
        snippetOf(matched, fits: _budget(words, 14)),
        1,
        5,
        before: true,
        after: true,
        reason: '5 words',
      );
      expectRun(
        snippetOf(matched, fits: _budget(words, 17)),
        1,
        6,
        before: true,
        after: false,
        reason: '6 words',
      );
      expectRun(
        snippetOf(matched, fits: _budget(words, 20)),
        0,
        6,
        before: false,
        after: false,
        reason: '7 words',
      );
    });

    test('it stops at the first word that does not fit, and does not try the other side after it', () {
      // The word after the first match is long; the word before it is short and would fit.
      final words = ['a', 'b', 'cc', 'd' * 12, 'e', 'f'];
      final matched = _flags(6, {2});
      expect(words[1], 'b');
      final s = snippetOf(matched, fits: _budget(words, 8));
      expectRun(s, 2, 2, before: true, after: true);
    });

    test('the flags are true exactly when words are left out on that side', () {
      final words = _words([3, 3, 3, 3, 3, 3]);
      // First word matched: nothing before it, so no mark before even when the budget is small.
      expectRun(
        snippetOf(_flags(6, {0}), fits: _budget(words, 7)),
        0,
        1,
        before: false,
        after: true,
      );
      // Last word matched: nothing after it.
      expectRun(
        snippetOf(_flags(6, {5}), fits: _budget(words, 7)),
        4,
        5,
        before: true,
        after: false,
      );
      // The window reaches the start only: no mark before, a mark after.
      expectRun(
        snippetOf(_flags(6, {1}), fits: _budget(words, 11)),
        0,
        2,
        before: false,
        after: true,
      );
      // The window reaches the end only: a mark before, none after.
      expectRun(
        snippetOf(_flags(6, {4}), fits: _budget(words, 11)),
        3,
        5,
        before: true,
        after: false,
      );
    });

    test(
      'when one side has no word left, the other side takes the whole budget',
      () {
        final words = _words([2, 2, 2, 2, 2, 2]);
        // The match is the last word: the run grows backwards only.
        expectRun(
          snippetOf(_flags(6, {5}), fits: _budget(words, 11)),
          2,
          5,
          before: true,
          after: false,
        );
        // The match is the first word: the run grows forwards only.
        expectRun(
          snippetOf(_flags(6, {0}), fits: _budget(words, 11)),
          0,
          3,
          before: false,
          after: true,
        );
      },
    );

    test('a single word wider than the budget is still returned alone', () {
      final words = ['a', 'b' * 30, 'c'];
      final s = snippetOf(_flags(3, {1}), fits: _budget(words, 5));
      expectRun(s, 1, 1, before: true, after: true);
      // Even with a budget of nothing at all.
      expectRun(
        snippetOf(_flags(3, {1}), fits: _budget(words, 0)),
        1,
        1,
        before: true,
        after: true,
      );
      expectRun(
        snippetOf([true], fits: (_, _) => false),
        0,
        0,
        before: false,
        after: false,
      );
    });

    test('a larger budget never gives a smaller run: every run contains the one of a smaller budget', () {
      final rng = Random(11);
      for (var round = 0; round < 60; round++) {
        final n = 1 + rng.nextInt(40);
        final words = _words([for (var i = 0; i < n; i++) 2 + rng.nextInt(9)]);
        final matched = _flags(n, {
          rng.nextInt(n),
          if (rng.nextBool()) rng.nextInt(n),
        });
        var prev = snippetOf(matched, fits: _budget(words, 0));
        for (var budget = 1; budget <= 500; budget += 3) {
          final s = snippetOf(matched, fits: _budget(words, budget));
          expect(
            s.from,
            lessThanOrEqualTo(prev.from),
            reason: 'n=$n budget=$budget',
          );
          expect(
            s.to,
            greaterThanOrEqualTo(prev.to),
            reason: 'n=$n budget=$budget',
          );
          prev = s;
        }
        // 500 characters hold every ayah of 40 words of at most 10 characters (439 at most).
        expectRun(
          prev,
          0,
          n - 1,
          before: false,
          after: false,
          reason: 'the whole ayah at the biggest budget',
        );
      }
    });

    test('the run always holds the first matched word and is made of consecutive words in range', () {
      final rng = Random(5);
      for (var round = 0; round < 200; round++) {
        final n = 1 + rng.nextInt(60);
        final words = _words([for (var i = 0; i < n; i++) 1 + rng.nextInt(12)]);
        final first = rng.nextInt(n);
        final matched = _flags(n, {
          first,
          for (var k = 0; k < 3; k++) first + rng.nextInt(n - first),
        });
        final s = snippetOf(matched, fits: _budget(words, rng.nextInt(120)));
        expect(s.from, lessThanOrEqualTo(first));
        expect(s.to, greaterThanOrEqualTo(first));
        expect(s.from, greaterThanOrEqualTo(0));
        expect(s.to, lessThan(n));
        expect(s.cutBefore, s.from > 0);
        expect(s.cutAfter, s.to < n - 1);
      }
    });

    test('it agrees with the one-word-at-a-time reading of the rule on 500 random ayat and budgets', () {
      final rng = Random(2026);
      for (var round = 0; round < 500; round++) {
        final n = 1 + rng.nextInt(130);
        final words = _words([for (var i = 0; i < n; i++) 1 + rng.nextInt(14)]);
        final matched = _flags(n, {
          for (var k = 0; k < 1 + rng.nextInt(3); k++) rng.nextInt(n),
        });
        final fits = _budget(words, rng.nextInt(500));
        final got = snippetOf(matched, fits: fits);
        final want = _oracle(matched, fits);
        expectRun(
          got,
          want.from,
          want.to,
          before: want.cutBefore,
          after: want.cutAfter,
          reason: 'n=$n',
        );
      }
    });

    test('it measures a 128-word ayah in at most 7 layouts (a binary search, not a word-by-word walk)', () {
      final words = _words([for (var i = 0; i < 128; i++) 4 + i % 5]);
      for (final budget in [0, 40, 300, 100000]) {
        var calls = 0;
        final inner = _budget(words, budget);
        final s = snippetOf(
          _flags(128, {64}),
          fits: (from, to) {
            calls++;
            return inner(from, to);
          },
        );
        expect(calls, lessThanOrEqualTo(7), reason: 'budget=$budget');
        expect(s.from, lessThanOrEqualTo(64));
        expect(s.to, greaterThanOrEqualTo(64));
      }
    });

    test('fits is only asked about runs that hold the first matched word, inside the ayah', () {
      final words = _words([for (var i = 0; i < 50; i++) 3 + i % 4]);
      final asked = <(int, int)>[];
      snippetOf(
        _flags(50, {20, 30}),
        fits: (from, to) {
          asked.add((from, to));
          return _budget(words, 90)(from, to);
        },
      );
      expect(asked, isNotEmpty);
      for (final (from, to) in asked) {
        expect(from, inInclusiveRange(0, 20));
        expect(to, inInclusiveRange(20, 49));
      }
    });

    test('no matched word: the run starts at the first word (a query always matches, so this is only a safe default)', () {
      final words = _words([3, 3, 3, 3]);
      final s = snippetOf(_flags(4, {}), fits: _budget(words, 7));
      expectRun(s, 0, 1, before: false, after: true);
    });

    test('an ayah with no word is a programming error', () {
      expect(
        () => snippetOf(const [], fits: (_, _) => true),
        throwsArgumentError,
      );
    });
  });

  group('over the real text (all 114 surah files)', () {
    late AyahIndex index;

    setUpAll(() async {
      index = await realIndex();
    });

    /// The flags of ayah [i] for the typed [words] (the way the search marks them).
    List<bool> flagsFor(int i, List<String> words) => index.matchedWords(
      i,
      ArabicFold.pattern(ArabicFold.query(words.join(' '))),
    );

    /// The characters of the run `from..to` of [stored], joined by single spaces.
    bool Function(int, int) fitsChars(List<String> stored, int budget) =>
        (from, to) => stored.sublist(from, to + 1).join(' ').length <= budget;

    test('for all 6,236 ayat, searching its own first three words: the snippet holds the first matched word and is a run of the stored words', () {
      var cuts = 0;
      for (var i = 0; i < index.ayahCount; i++) {
        final stored = index.storedWords(i);
        final matched = flagsFor(i, stored.take(3).toList());
        final first = matched.indexOf(true);
        expect(
          first,
          greaterThanOrEqualTo(0),
          reason: 'ayah ${index.refOf(i).key} finds itself',
        );
        expect(matched.length, stored.length);
        // Three budgets: a tight one, a typical one (three lines of a phone), and a huge one.
        for (final budget in [1, 90, 100000]) {
          final s = snippetOf(matched, fits: fitsChars(stored, budget));
          final reason = '${index.refOf(i).key} budget $budget';
          expect(s.from, lessThanOrEqualTo(first), reason: reason);
          expect(s.to, greaterThanOrEqualTo(first), reason: reason);
          expect(s.from, greaterThanOrEqualTo(0), reason: reason);
          expect(s.to, lessThan(stored.length), reason: reason);
          expect(s.cutBefore, s.from > 0, reason: reason);
          expect(s.cutAfter, s.to < stored.length - 1, reason: reason);
          // The words shown are the stored words, character for character: never the folded or the typed form.
          final shown = stored.sublist(s.from, s.to + 1);
          expect(
            shown,
            index.storedWords(i).sublist(s.from, s.to + 1),
            reason: reason,
          );
          for (final word in shown) {
            expect(stored.contains(word), isTrue, reason: reason);
          }
          if (budget == 1) {
            expect(
              shown,
              [stored[first]],
              reason:
                  '$reason: one word is wider than the budget, so it is alone',
            );
          }
          if (budget == 100000) {
            expect(
              [s.from, s.to, s.cutBefore, s.cutAfter],
              [0, stored.length - 1, false, false],
              reason: reason,
            );
          }
          if (budget == 90) {
            final whole = stored.join(' ').length <= 90;
            if (whole) {
              expect(
                [s.cutBefore, s.cutAfter],
                [false, false],
                reason: '$reason: it fits whole',
              );
            } else {
              expect(
                s.cutBefore || s.cutAfter,
                isTrue,
                reason: '$reason: words were left out',
              );
              if (shown.length > 1) {
                expect(
                  shown.join(' ').length,
                  lessThanOrEqualTo(90),
                  reason: reason,
                );
              }
              cuts++;
            }
          }
        }
      }
      expect(
        cuts,
        greaterThan(1000),
        reason: 'many ayat are longer than a tight budget',
      );
    });

    test('2:282 (128 words): a 40-character budget leaves words out on both sides, a huge budget gives the whole ayah', () {
      final i = index.indexOf(const AyahRef(2, 282));
      final stored = index.storedWords(i);
      expect(stored.length, 128);
      // Words from the middle of the ayah, so there is something on both sides.
      final matched = flagsFor(i, stored.sublist(60, 63));
      final first = matched.indexOf(true);
      expect(first, inInclusiveRange(30, 100));
      final tight = snippetOf(matched, fits: fitsChars(stored, 40));
      expect(tight.cutBefore, isTrue);
      expect(tight.cutAfter, isTrue);
      expect(tight.from, lessThanOrEqualTo(first));
      expect(tight.to, greaterThanOrEqualTo(first));
      expect(
        stored.sublist(tight.from, tight.to + 1).join(' ').length,
        lessThanOrEqualTo(40),
      );
      final whole = snippetOf(matched, fits: fitsChars(stored, 100000));
      expect(
        [whole.from, whole.to, whole.cutBefore, whole.cutAfter],
        [0, 127, false, false],
      );
    });

    test('a larger budget never gives a smaller run, over 300 real ayat spread over the Quran', () {
      for (var i = 0; i < index.ayahCount; i += 21) {
        final stored = index.storedWords(i);
        final matched = flagsFor(
          i,
          stored.skip(stored.length ~/ 2).take(2).toList(),
        );
        var prev = snippetOf(matched, fits: fitsChars(stored, 0));
        for (var budget = 10; budget <= 600; budget += 30) {
          final s = snippetOf(matched, fits: fitsChars(stored, budget));
          expect(
            s.from,
            lessThanOrEqualTo(prev.from),
            reason: '${index.refOf(i).key} budget $budget',
          );
          expect(
            s.to,
            greaterThanOrEqualTo(prev.to),
            reason: '${index.refOf(i).key} budget $budget',
          );
          prev = s;
        }
      }
    });
  });
}
