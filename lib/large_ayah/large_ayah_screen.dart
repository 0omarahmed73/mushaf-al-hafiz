import 'package:material_ui/material_ui.dart';

import '../mushaf/models.dart';
import '../mushaf/mushaf_page.dart' show StarOrnament, kBasmallah, kQuranFont, kTitleFont;
import '../mushaf/page_font_loader.dart';
import '../mushaf/page_look.dart';
import '../theme.dart' show kUiFont;
import 'large_ayah_strings.dart';
import 'page_screens.dart';
import 'screen_layout.dart';

/// One screen of the large-ayah view (feature 015, research D1, D2, D9; contracts/ui.md): a header with the surah, the
/// ayat and the page; the opening of a surah when the screen has one; the ayat, each from a new line, right-aligned, in
/// the page's own QCF V2 glyphs at the [geometry]'s size; «تتبع» under a part that goes on. Every word is a `Text` keyed
/// `ValueKey('lw<id>')`. The phone's text scale is switched off: the size is the app's own.
class LargeAyahScreen extends StatelessWidget {
  const LargeAyahScreen({
    super.key,
    required this.screen,
    required this.meta,
    required this.geometry,
    this.look = PageLook.screen,
    this.highlightedWordIds = const {},
    this.tintedWordIds = const {},
    this.onWordLongPress,
  });

  final LargeScreen screen;
  final MushafMeta meta;
  final LargeGeometry geometry;
  final PageLook look;
  final Set<int> highlightedWordIds;
  final Set<int> tintedWordIds;
  final void Function(MushafWord word)? onWordLongPress;

  String get _header {
    final ayat = screen.ayat;
    final first = ayat.first;
    return LargeAyahStrings.header(
      surahName: meta.surah(first.surah).name,
      first: first.ayah,
      last: ayat.last.surah == first.surah ? ayat.last.ayah : first.ayah,
      page: screen.page,
      part: screen.part,
    );
  }

  /// The end marker of each ayah is its last word; a part that goes on has none.
  Set<int> get _endMarkers => {
    for (final item in screen.items)
      if (item is AyahItem && item.lines.isNotEmpty && !screen.continues) item.lines.last.last.id,
  };

  @override
  Widget build(BuildContext context) {
    final quiet = TextStyle(fontFamily: kUiFont, fontSize: 15, height: 1.3, color: look.ink);
    final markers = _endMarkers;
    return MediaQuery.withNoTextScaling(
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: ColoredBox(
          color: look.paper,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: LargeGeometry.hPad, vertical: LargeGeometry.vPad),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: LargeGeometry.headerHeight,
                  // The end of the header is kept for the reader's «المصحف» button (contracts/ui.md).
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _header,
                          key: const ValueKey('large-header'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: quiet,
                        ),
                      ),
                      const SizedBox(width: LargeGeometry.headerEndReserve),
                    ],
                  ),
                ),
                Expanded(
                  child: ClipRect(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (final item in screen.items)
                          ...switch (item) {
                            OpeningItem(:final line) => [_opening(line)],
                            AyahItem(:final lines) => [for (final l in lines) _line(l, markers)],
                          },
                      ],
                    ),
                  ),
                ),
                SizedBox(
                  height: LargeGeometry.footerHeight,
                  child: screen.continues
                      ? Align(
                          alignment: AlignmentDirectional.centerEnd,
                          child: Text(LargeAyahStrings.continues, key: const ValueKey('large-continues'), style: quiet),
                        )
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _line(List<MushafWord> words, Set<int> markers) {
    final g = geometry;
    final children = <Widget>[];
    for (var i = 0; i < words.length; i++) {
      if (i > 0) children.add(SizedBox(width: g.wordGap));
      children.add(_word(words[i], markers));
    }
    Widget row = Row(mainAxisSize: MainAxisSize.min, children: children);
    // A single word wider than the line is scaled down to fit (research D3); every other line already fits.
    if (words.length == 1) {
      row = FittedBox(fit: BoxFit.scaleDown, alignment: AlignmentDirectional.centerStart, child: row);
    }
    return SizedBox(
      height: g.lineHeight,
      child: Align(alignment: AlignmentDirectional.centerStart, child: row),
    );
  }

  Widget _word(MushafWord word, Set<int> markers) {
    final color = markers.contains(word.id) ? (look.endMarker ?? look.ink) : look.ink;
    Widget child = Text(
      word.glyph,
      key: ValueKey('lw${word.id}'),
      softWrap: false,
      style: TextStyle(
        fontFamily: PageFontLoader.familyOf(screen.page),
        fontSize: geometry.fontSize,
        height: 1,
        color: color,
      ),
    );
    final fill = highlightedWordIds.contains(word.id)
        ? look.highlight
        : tintedWordIds.contains(word.id)
        ? look.bookmarkTint
        : null;
    if (fill != null) {
      child = DecoratedBox(
        decoration: BoxDecoration(color: fill, borderRadius: BorderRadius.circular(6)),
        child: child,
      );
    }
    final press = onWordLongPress;
    if (press != null) {
      child = GestureDetector(behavior: HitTestBehavior.opaque, onLongPress: () => press(word), child: child);
    }
    return child;
  }

  Widget _opening(OpeningLine line) {
    final g = geometry;
    final Widget content = switch (line.kind) {
      OpeningKind.basmala => Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            kBasmallah,
            softWrap: false,
            style: TextStyle(fontFamily: kQuranFont, fontSize: g.fontSize * 0.7, height: 1.2, color: look.ink),
          ),
        ),
      ),
      OpeningKind.surahTitle => _title(line.surah!),
    };
    return SizedBox(height: g.lineHeight, child: content);
  }

  Widget _title(int surah) {
    final g = geometry;
    final color = look.bannerText;
    final text = FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(
        'سورة ${meta.surah(surah).name}',
        softWrap: false,
        style: TextStyle(
          fontFamily: kTitleFont,
          fontVariations: const [FontVariation('wght', 700)],
          fontSize: g.fontSize * 0.6,
          height: 1.25,
          color: color,
        ),
      ),
    );
    if (look.bannerStyle == PageBannerStyle.rules) {
      final rule = DecoratedBox(decoration: BoxDecoration(color: look.bannerRule ?? color.withValues(alpha: 0.3)));
      return Center(
        child: Row(
          children: [
            Expanded(child: SizedBox(height: 1, child: rule)),
            const SizedBox(width: 16),
            Flexible(flex: 4, child: text),
            const SizedBox(width: 16),
            Expanded(child: SizedBox(height: 1, child: rule)),
          ],
        ),
      );
    }
    return Center(
      child: Container(
        height: g.lineHeight * 0.76,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: look.bannerFill,
          border: Border.all(color: look.frame, width: look.frameWidth),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            const SizedBox(width: 12),
            StarOrnament(color: color),
            const SizedBox(width: 16),
            Expanded(child: Center(child: text)),
            const SizedBox(width: 16),
            StarOrnament(color: color),
            const SizedBox(width: 12),
          ],
        ),
      ),
    );
  }
}
