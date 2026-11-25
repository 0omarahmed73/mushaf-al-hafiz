/// The pure screen layout of the large-ayah view (feature 015, research D1 and D3): one page's ayat, with each word's
/// width at the chosen size, become that page's screens. No widget, no font: the widths come from `WordMeasurer`.
library;

import 'package:flutter/foundation.dart';

import '../ayah/ayah_ref.dart';
import '../mushaf/models.dart';

enum OpeningKind { surahTitle, basmala }

/// A line of the page that opens a surah: its title (with [surah]) or the basmala.
@immutable
class OpeningLine {
  const OpeningLine(this.kind, {this.surah});

  final OpeningKind kind;
  final int? surah;

  @override
  bool operator ==(Object other) => other is OpeningLine && other.kind == kind && other.surah == surah;

  @override
  int get hashCode => Object.hash(kind, surah);

  @override
  String toString() => 'OpeningLine($kind, $surah)';
}

/// One ayah of a page as the layout needs it: its words in order, their widths in px, the opening lines that come
/// before it on the page, and, for the page's last ayah only, the opening lines after it (18 pages end with the next
/// surah's title on their last line, e.g. page 76; it stays on its own page, at the end of the page's last screen).
class LayoutAyah {
  const LayoutAyah({
    required this.ref,
    required this.words,
    required this.widths,
    this.opening = const [],
    this.trailing = const [],
  }) : assert(words.length == widths.length);

  final AyahRef ref;
  final List<MushafWord> words;
  final List<double> widths;
  final List<OpeningLine> opening;
  final List<OpeningLine> trailing;

  LayoutAyah withWidths(List<double> widths) =>
      LayoutAyah(ref: ref, words: words, widths: widths, opening: opening, trailing: trailing);
}

/// What a screen draws, top to bottom.
sealed class ScreenItem {
  const ScreenItem();
}

class OpeningItem extends ScreenItem {
  const OpeningItem(this.line);

  final OpeningLine line;
}

/// The lines of one ayah (or of one part of it) on a screen.
class AyahItem extends ScreenItem {
  const AyahItem(this.ref, this.lines);

  final AyahRef ref;
  final List<List<MushafWord>> lines;
}

/// One screen of the view: always of one [page] (FR-008); 1 to 3 whole ayat, or one [part] of a split ayah (FR-019).
class LargeScreen {
  const LargeScreen({required this.page, required this.items, this.part});

  final int page;
  final List<ScreenItem> items;

  /// Null for whole ayat; the part's number (1-based) and the number of parts for a split ayah.
  final ({int number, int of})? part;

  List<AyahRef> get ayat => [
    for (final i in items)
      if (i is AyahItem) i.ref,
  ];

  List<OpeningLine> get opening => [
    for (final i in items)
      if (i is OpeningItem) i.line,
  ];

  /// Every line of words, in order.
  List<List<MushafWord>> get lines => [
    for (final i in items)
      if (i is AyahItem) ...i.lines,
  ];

  /// Every word of the screen, in order.
  Iterable<MushafWord> get words => lines.expand((l) => l);

  bool get continues => part != null && part!.number < part!.of;
}

/// The ayat of [page] in order, with their words and the opening lines (surah title, basmala) that come before each.
List<LayoutAyah> pageAyat(PageData page) {
  final out = <LayoutAyah>[];
  var pending = <OpeningLine>[]; // opening lines seen since the last ayah began
  AyahRef? current;
  var currentOpening = const <OpeningLine>[];
  var words = <MushafWord>[];
  void flush() {
    final ref = current;
    if (ref != null) {
      out.add(LayoutAyah(ref: ref, words: words, widths: List.filled(words.length, 0), opening: currentOpening));
    }
    current = null;
    words = [];
  }

  for (final line in page.lines) {
    switch (line.type) {
      case LineType.surahName:
        flush();
        pending = [...pending, OpeningLine(OpeningKind.surahTitle, surah: line.surah)];
      case LineType.basmallah:
        flush();
        pending = [...pending, const OpeningLine(OpeningKind.basmala)];
      case LineType.ayah:
        for (final w in line.words) {
          final ref = AyahRef(w.surah, w.ayah);
          if (ref != current) {
            flush();
            current = ref;
            currentOpening = pending;
            pending = [];
          }
          words.add(w);
        }
    }
  }
  flush();
  if (pending.isNotEmpty && out.isNotEmpty) {
    final last = out.removeLast();
    out.add(
      LayoutAyah(ref: last.ref, words: last.words, widths: last.widths, opening: last.opening, trailing: pending),
    );
  }
  return out;
}

/// The lines of [ayah]: greedy wrapping, a word goes to the next line when it does not fit; a word wider than the line
/// gets a line of its own.
List<List<MushafWord>> wrapAyah(LayoutAyah ayah, double lineWidth, double wordGap) {
  final lines = <List<MushafWord>>[];
  var line = <MushafWord>[];
  var used = 0.0;
  for (var i = 0; i < ayah.words.length; i++) {
    final w = ayah.widths[i];
    final need = line.isEmpty ? w : used + wordGap + w;
    if (line.isNotEmpty && need > lineWidth) {
      lines.add(line);
      line = [ayah.words[i]];
      used = w;
    } else {
      line.add(ayah.words[i]);
      used = need;
    }
  }
  if (line.isNotEmpty) lines.add(line);
  return lines;
}

/// The screens of one page (research D3). A screen takes up to [count] whole ayat while their lines, and the opening lines
/// before them, fit [linesPerScreen], and always at least one ayah; an ayah that alone does not fit is split into parts of
/// whole lines, each a screen of its own, the first part also holding the ayah's opening lines.
List<LargeScreen> layoutPage({
  required int page,
  required List<LayoutAyah> ayat,
  required double lineWidth,
  required double wordGap,
  required int linesPerScreen,
  required int count,
}) {
  if (count < 1 || count > 3) throw ArgumentError.value(count, 'count', 'must be 1, 2 or 3');
  if (linesPerScreen < 3) throw ArgumentError.value(linesPerScreen, 'linesPerScreen', 'must be at least 3');
  if (lineWidth <= 0) throw ArgumentError.value(lineWidth, 'lineWidth', 'must be positive');

  final wrapped = [for (final a in ayat) wrapAyah(a, lineWidth, wordGap)];
  int height(int i) => ayat[i].opening.length + wrapped[i].length + ayat[i].trailing.length;
  List<ScreenItem> itemsOf(int i, List<List<MushafWord>> lines, {bool withOpening = true, bool withTrailing = true}) =>
      [
        if (withOpening)
          for (final o in ayat[i].opening) OpeningItem(o),
        AyahItem(ayat[i].ref, lines),
        if (withTrailing)
          for (final o in ayat[i].trailing) OpeningItem(o),
      ];

  final screens = <LargeScreen>[];
  var i = 0;
  while (i < ayat.length) {
    if (height(i) > linesPerScreen) {
      final lines = wrapped[i];
      final chunks = <List<List<MushafWord>>>[];
      var start = 0;
      var room = linesPerScreen - ayat[i].opening.length;
      while (start < lines.length) {
        final end = (start + room).clamp(start + 1, lines.length);
        chunks.add(lines.sublist(start, end));
        start = end;
        room = linesPerScreen;
      }
      // The trailing title needs room on the last part; if there is none, the last line moves to a new last part.
      final tail = ayat[i].trailing.length;
      if (tail > 0 && chunks.last.length + tail + (chunks.length == 1 ? ayat[i].opening.length : 0) > linesPerScreen) {
        final last = chunks.removeLast();
        chunks
          ..add(last.sublist(0, last.length - 1))
          ..add([last.last]);
        if (chunks[chunks.length - 2].isEmpty) chunks.removeAt(chunks.length - 2);
      }
      for (var c = 0; c < chunks.length; c++) {
        screens.add(
          LargeScreen(
            page: page,
            items: itemsOf(i, chunks[c], withOpening: c == 0, withTrailing: c == chunks.length - 1),
            part: (number: c + 1, of: chunks.length),
          ),
        );
      }
      i++;
      continue;
    }
    final items = itemsOf(i, wrapped[i]);
    var used = height(i);
    var taken = 1;
    while (taken < count && i + taken < ayat.length) {
      final next = i + taken;
      if (used + height(next) > linesPerScreen) break;
      items.addAll(itemsOf(next, wrapped[next]));
      used += height(next);
      taken++;
    }
    screens.add(LargeScreen(page: page, items: items));
    i += taken;
  }
  return screens;
}
