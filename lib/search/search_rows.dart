/// The rows and lines of the search screen (feature 011; contracts/ui.md "Rows", "Headings, lines and the more-line"): the
/// group headings, the surah row, the ayah row with its snippet and the one-line messages. Every colour is a token of the look
/// in use and every Arabic string comes from `search_strings.dart`.
library;

import 'package:material_ui/material_ui.dart';

import '../ayah/ui/reading_text.dart';
import '../mushaf/models.dart';
import '../mushaf/mushaf_page.dart' show kQuranFont;
import '../theme.dart';
import 'ayah_target.dart';
import 'search_service.dart';
import 'search_strings.dart';
import 'snippet.dart';

/// A group heading: the visible text («السور · N») and, to a screen reader, a header with its own label («السور، عدد
/// النتائج N»).
class SearchHeading extends StatelessWidget {
  const SearchHeading({super.key, required this.text, required this.semantics});

  final String text;
  final String semantics;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      label: semantics,
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Text(text, style: headingStyle(18, context.look.heading)),
      ),
    );
  }
}

/// A line of the ayah group (nothing typed, a second letter wanted, preparing, failed, nothing found), centred with 24 dp of
/// padding, optionally with a second line of advice under it. Nothing in it is red.
class SearchLine extends StatelessWidget {
  const SearchLine({super.key, required this.text, this.advice});

  final String text;
  final String? advice;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(color: context.look.textSecondary, fontSize: 15);
    final advice = this.advice;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(text, textAlign: TextAlign.center, style: style),
          if (advice != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(advice, textAlign: TextAlign.center, style: style),
            ),
        ],
      ),
    );
  }
}

/// The button under the failure line («إعادة المحاولة»), at least 48 px high.
class SearchRetryButton extends StatelessWidget {
  const SearchRetryButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 24),
        child: FilledButton(
          key: const ValueKey('search-retry'),
          style: FilledButton.styleFrom(minimumSize: const Size(64, 48)),
          onPressed: onPressed,
          child: const Text(kSearchRetry),
        ),
      ),
    );
  }
}

/// The surah row, as the index writes its row: the number, the name as the index writes it and «ص N» (its first page). A tap
/// hands the first page to [onChosen].
class SurahRow extends StatelessWidget {
  const SurahRow({super.key, required this.surah, required this.onChosen});

  final SurahInfo surah;
  final ValueChanged<int> onChosen;

  @override
  Widget build(BuildContext context) {
    void choose() => onChosen(surah.startPage);
    return Semantics(
      button: true,
      label: kSurahRowSemantics(surah.name, surah.startPage),
      onTap: choose,
      excludeSemantics: true,
      child: ListTile(
        leading: Text('${surah.number}'),
        title: Text(surah.name),
        trailing: Text(kPageShort(surah.startPage)),
        onTap: choose,
      ),
    );
  }
}

/// The ayah row: «{name} · آية N» and «ص N», then the snippet, a run of whole stored words around the first matched word, at
/// most three lines, the matched words in the accent colour and underlined. A tap hands `AyahTarget(ref, page)` to [onChosen].
/// To a screen reader it is one button: the place, then the words shown (without «…»).
class AyahRow extends StatefulWidget {
  const AyahRow({
    super.key,
    required this.hit,
    required this.surahName,
    required this.onChosen,
  });

  final AyahHit hit;

  /// The surah's name as the index writes it.
  final String surahName;
  final ValueChanged<AyahTarget> onChosen;

  /// The size of the snippet's words at the reading size 100%.
  static const double snippetSize = 20;

  /// The most lines a snippet takes.
  static const int snippetLines = 3;

  @override
  State<AyahRow> createState() => _AyahRowState();
}

class _AyahRowState extends State<AyahRow> {
  /// The last snippet and what it was measured for (the ayah, the width, the style and the scale).
  SnippetWords? _snippet;
  Object? _measuredFor;

  void _choose() =>
      widget.onChosen(AyahTarget(widget.hit.ref, widget.hit.page));

  /// The words `from..to` of the ayah as they are drawn: every stored word unchanged, a space between two, «…» where words
  /// were left out.
  TextSpan _span(
    int from,
    int to, {
    required TextStyle emphasis,
    required TextStyle cut,
    TextStyle? base,
  }) {
    final hit = widget.hit;
    return TextSpan(
      style: base,
      children: [
        if (from > 0) TextSpan(text: '$kSnippetCut ', style: cut),
        for (var i = from; i <= to; i++) ...[
          TextSpan(text: hit.words[i], style: hit.matched[i] ? emphasis : null),
          if (i < to) const TextSpan(text: ' '),
        ],
        if (to < hit.words.length - 1)
          TextSpan(text: ' $kSnippetCut', style: cut),
      ],
    );
  }

  SnippetWords _snippetFor({
    required double width,
    required TextStyle base,
    required TextStyle emphasis,
    required TextStyle cut,
    required TextScaler scaler,
    required TextDirection direction,
    required Locale? locale,
  }) {
    final measuredFor = (widget.hit, width, base, scaler, direction, locale);
    final known = _snippet;
    if (known != null && measuredFor == _measuredFor) return known;
    final painter = TextPainter(
      textDirection: direction,
      textScaler: scaler,
      locale: locale,
      maxLines: AyahRow.snippetLines,
    );
    final snippet = snippetOf(
      widget.hit.matched,
      fits: (from, to) {
        painter
          ..text = _span(from, to, base: base, emphasis: emphasis, cut: cut)
          ..layout(maxWidth: width);
        return !painter.didExceedMaxLines;
      },
    );
    painter.dispose();
    _measuredFor = measuredFor;
    return _snippet = snippet;
  }

  @override
  Widget build(BuildContext context) {
    final look = context.look;
    final hit = widget.hit;
    final factor = ReadingScope.of(context).factor;
    // the scale the ReadingScope below gives the snippet: the system font, capped so that size times font stays at 3x
    final scaler = MediaQuery.textScalerOf(context)
        .clamp(maxScaleFactor: kMaxReadingScale / factor);
    final base = DefaultTextStyle.of(context).style.merge(
      TextStyle(
        fontFamily: kQuranFont,
        fontSize: AyahRow.snippetSize * factor,
        height: 2.0,
        color: look.text,
      ),
    );
    final emphasis = TextStyle(
      color: look.accent,
      decoration: TextDecoration.underline,
      decorationColor: look.accent,
      decorationThickness: 2,
    );
    final cut = TextStyle(color: look.textSecondary);
    final direction = Directionality.of(context);
    final locale = Localizations.maybeLocaleOf(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        const side = 16.0;
        final snippet = _snippetFor(
          width: constraints.maxWidth - 2 * side,
          base: base,
          emphasis: emphasis,
          cut: cut,
          scaler: scaler,
          direction: direction,
          locale: locale,
        );
        final shown = hit.words.sublist(snippet.from, snippet.to + 1).join(' ');
        final place = kAyahRowSemantics(
          widget.surahName,
          hit.ref.ayah,
          hit.page,
        );
        return Semantics(
          button: true,
          label: '$place\n$shown',
          onTap: _choose,
          excludeSemantics: true,
          child: InkWell(
            onTap: _choose,
            child: Container(
              constraints: const BoxConstraints(minHeight: 56),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: look.line)),
              ),
              padding: const EdgeInsets.fromLTRB(side, 10, side, 10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          kAyahRowTitle(widget.surahName, hit.ref.ayah),
                          style: TextStyle(
                            color: look.text,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        kPageShort(hit.page),
                        style: TextStyle(
                          color: look.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  ReadingScope(
                    child: Text.rich(
                      _span(
                        snippet.from,
                        snippet.to,
                        emphasis: emphasis,
                        cut: cut,
                      ),
                      key: ValueKey('ayah-snippet-${hit.ref.key}'),
                      style: base,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
