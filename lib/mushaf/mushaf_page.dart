import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../theme.dart';
import 'models.dart';
import 'page_look.dart' show PageBannerStyle;

/// The widest justified line in any QCF V2 page font is 16.15 em; the font size is the text width
/// divided by this (measured over all 604 fonts), so every line of every page fits.
const double kMaxLineEm = 16.2;

/// Tallest line box of the page fonts (hhea ascent + descent) in em.
const double kLineBoxEm = 1.8;

const String kBasmallah = 'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ';
const String kQuranFont = 'AmiriQuran';

/// Font of the surah title in its banner (Reem Kufi, bold).
const String kTitleFont = 'ReemKufi';

/// Layout numbers shared by [MushafPage] and [MushafPageLoading] so a loading page has the same
/// geometry as the finished one.
class _Geometry {
  _Geometry(BoxConstraints c)
      : width = math.max(0, c.maxWidth - 2 * hPad),
        lineHeight = math.max(1, (c.maxHeight - 2 * vPad - numberHeight) / 15) {
    fontSize = math.min(width / kMaxLineEm, lineHeight / kLineBoxEm);
  }

  static const double hPad = 6;
  static const double vPad = 6;
  static const double numberHeight = 28;

  final double width;
  final double lineHeight;
  late final double fontSize;
}

/// One Mushaf page, drawn word by word from the page's own font. Each word is a `Text` keyed
/// `ValueKey('w<id>')` so later features can hide a word (it keeps its space) or highlight it.
class MushafPage extends StatelessWidget {
  const MushafPage({
    super.key,
    required this.data,
    required this.meta,
    required this.fontFamily,
    this.highlightedWordIds = const {},
    this.hiddenWordIds = const {},
    this.onWordTap,
    this.onWordLongPress,
    this.onPageNumberTap,
    this.textColor,
    this.highlightColor = const Color(0x55FFC107),
    this.frameColor,
    this.frameWidth = 1.5,
    this.bannerColor,
    this.bannerTextColor,
    this.bannerStyle = PageBannerStyle.framed,
    this.bannerRuleColor,
    this.numberColor,
    this.endMarkerColor,
  });

  final PageData data;
  final MushafMeta meta;

  /// Family of this page's font; it must already be loaded (see `PageFontLoader`).
  final String fontFamily;
  final Set<int> highlightedWordIds;
  final Set<int> hiddenWordIds;
  final void Function(MushafWord word)? onWordTap;
  final void Function(MushafWord word)? onWordLongPress;

  /// A tap on the page number (the reader opens its «go to page» popup); null leaves it plain text.
  final VoidCallback? onPageNumberTap;
  final Color? textColor;
  final Color highlightColor;
  final Color? frameColor;

  /// Width of the surah banner outline.
  final double frameWidth;

  /// Fill of the surah-title banner (transparent when null) and the colour of its text.
  final Color? bannerColor;
  final Color? bannerTextColor;

  /// How the surah title is drawn: in a framed banner, or between two hairlines of [bannerRuleColor].
  final PageBannerStyle bannerStyle;
  final Color? bannerRuleColor;

  /// The colour of the page number (the text colour when null) and of the ayah-end markers listed in
  /// [PageData.endMarkerIds] (the text colour when null). Colours only: nothing about the layout depends on them.
  final Color? numberColor;
  final Color? endMarkerColor;

  @override
  Widget build(BuildContext context) {
    final color = textColor ?? DefaultTextStyle.of(context).style.color ?? const Color(0xFF000000);
    final frame = frameColor ?? color.withValues(alpha: 0.6);
    return Directionality(
      textDirection: TextDirection.rtl,
      child: LayoutBuilder(builder: (context, constraints) {
        final g = _Geometry(constraints);
        return Column(
          children: [
            const SizedBox(height: _Geometry.vPad),
            SizedBox(
              height: g.lineHeight * 15,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [for (final line in data.lines) _line(line, g, color, frame)],
                ),
              ),
            ),
            SizedBox(
              height: _Geometry.numberHeight,
              child: Center(child: _pageNumber(numberColor ?? color)),
            ),
            const SizedBox(height: _Geometry.vPad),
          ],
        );
      }),
    );
  }

  /// The page number, a wide button when [onPageNumberTap] is given (the tap does not reach the page's own
  /// tap that shows or hides the bars).
  Widget _pageNumber(Color color) {
    final number = Text(
      '${data.page}',
      key: const ValueKey('page-number'),
      style: TextStyle(fontFamily: kUiFont, color: color, fontSize: 14),
    );
    final onTap = onPageNumberTap;
    if (onTap == null) return number;
    return Semantics(
      button: true,
      label: 'الانتقال إلى صفحة، أنت في الصفحة ${data.page}',
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(
          width: 96,
          height: _Geometry.numberHeight,
          child: Center(child: number),
        ),
      ),
    );
  }

  Widget _line(MushafLine line, _Geometry g, Color color, Color frame) {
    return SizedBox(
      key: ValueKey('line-${line.number}'),
      width: g.width,
      height: g.lineHeight,
      child: switch (line.type) {
        LineType.ayah => _ayahLine(line, g, color),
        LineType.surahName => _surahTitle(line, g, color, frame),
        // Smaller than the page text and lifted, so it neither dwarfs the lines nor touches the next one.
        LineType.basmallah => Align(
            alignment: const Alignment(0, -0.45),
            child: Text(
              kBasmallah,
              softWrap: false,
              style: TextStyle(fontFamily: kQuranFont, fontSize: g.fontSize * 0.82, height: 1.2, color: color),
            ),
          ),
      },
    );
  }

  Widget _ayahLine(MushafLine line, _Geometry g, Color color) {
    return Row(
      mainAxisAlignment: line.centered ? MainAxisAlignment.center : MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [for (final w in line.words) _word(w, g, color)],
    );
  }

  Widget _word(MushafWord word, _Geometry g, Color color) {
    final marker = endMarkerColor;
    final wordColor = marker != null && data.endMarkerIds.contains(word.id) ? marker : color;
    Widget child = Text(
      word.glyph,
      key: ValueKey('w${word.id}'),
      softWrap: false,
      style: TextStyle(fontFamily: fontFamily, fontSize: g.fontSize, color: wordColor),
    );
    if (highlightedWordIds.contains(word.id)) {
      child = DecoratedBox(
        decoration: BoxDecoration(color: highlightColor, borderRadius: BorderRadius.circular(4)),
        child: child,
      );
    }
    if (hiddenWordIds.contains(word.id)) {
      child = Opacity(opacity: 0, child: child);
    }
    if (onWordTap != null || onWordLongPress != null) {
      child = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onWordTap == null ? null : () => onWordTap!(word),
        onLongPress: onWordLongPress == null ? null : () => onWordLongPress!(word),
        child: child,
      );
    }
    return child;
  }

  Widget _surahTitle(MushafLine line, _Geometry g, Color color, Color frame) {
    final surah = line.surah;
    final titleColor = bannerTextColor ?? color;
    final star = StarOrnament(color: titleColor);
    final title = Flexible(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          'سورة ${meta.surah(surah!).name}',
          softWrap: false,
          overflow: TextOverflow.visible,
          style: TextStyle(
            fontFamily: kTitleFont,
            fontVariations: const [FontVariation('wght', 700)],
            fontSize: g.fontSize * 1.05,
            height: 1.25,
            leadingDistribution: TextLeadingDistribution.even,
            color: titleColor,
          ),
        ),
      ),
    );
    if (bannerStyle == PageBannerStyle.rules) {
      // The title between two 1 px hairlines: no box, no fill, no stars; the same height and place as the banner.
      final rule = DecoratedBox(decoration: BoxDecoration(color: bannerRuleColor ?? titleColor.withValues(alpha: 0.3)));
      return Align(
        alignment: const Alignment(0, -0.6),
        child: Container(
          width: double.infinity,
          height: g.lineHeight * 0.76,
          margin: const EdgeInsets.symmetric(horizontal: 8),
          alignment: Alignment.center,
          child: Row(
            children: [
              Expanded(child: SizedBox(height: 1, child: rule)),
              const SizedBox(width: 16),
              title,
              const SizedBox(width: 16),
              Expanded(child: SizedBox(height: 1, child: rule)),
            ],
          ),
        ),
      );
    }
    // Slightly shorter than the line and sitting high in it, so there is a clear gap below the banner.
    return Align(
      alignment: const Alignment(0, -0.6),
      child: Container(
        width: double.infinity,
        height: g.lineHeight * 0.76,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: bannerColor,
          border: Border.all(color: frame, width: frameWidth),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            star,
            const SizedBox(width: 16),
            // A long name shrinks to fit; a tight line height and visible overflow keep the glyphs
            // from being clipped (a Text taller than its box is clipped by default).
            title,
            const SizedBox(width: 16),
            star,
          ],
        ),
      ),
    );
  }
}

/// A four-pointed star: the ornament on both sides of a surah title, also used on the About screen.
class StarOrnament extends StatelessWidget {
  const StarOrnament({super.key, required this.color, this.size = 15});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: size,
        height: size,
        child: CustomPaint(painter: _StarPainter(color)),
      );
}

class _StarPainter extends CustomPainter {
  const _StarPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2;
    final waist = r * 0.28;
    final path = Path()
      ..moveTo(c.dx, c.dy - r)
      ..lineTo(c.dx + waist, c.dy - waist)
      ..lineTo(c.dx + r, c.dy)
      ..lineTo(c.dx + waist, c.dy + waist)
      ..lineTo(c.dx, c.dy + r)
      ..lineTo(c.dx - waist, c.dy + waist)
      ..lineTo(c.dx - r, c.dy)
      ..lineTo(c.dx - waist, c.dy - waist)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_StarPainter old) => old.color != color;
}

/// Shown instead of [MushafPage] while the page's font is loading: the same empty layout area and
/// the page number, never the text in a substitute font (spec FR-008a).
class MushafPageLoading extends StatelessWidget {
  const MushafPageLoading({super.key, required this.page, this.textColor, this.numberColor});

  final int page;
  final Color? textColor;

  /// The colour of the page number; [textColor] when null.
  final Color? numberColor;

  @override
  Widget build(BuildContext context) {
    final color = textColor ?? DefaultTextStyle.of(context).style.color ?? const Color(0xFF000000);
    return LayoutBuilder(builder: (context, constraints) {
      final g = _Geometry(constraints);
      return Column(
        children: [
          SizedBox(height: _Geometry.vPad + g.lineHeight * 15),
          SizedBox(
            height: _Geometry.numberHeight,
            child: Center(
              child: Directionality(
                textDirection: TextDirection.rtl,
                child: Text('$page', key: const ValueKey('page-number'), style: TextStyle(fontFamily: kUiFont, color: numberColor ?? color, fontSize: 14)),
              ),
            ),
          ),
        ],
      );
    });
  }
}
